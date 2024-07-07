//--------------------------------------------------------------------------------
class RoadItem
{
    int m_SurfaceIdx = 0;
    int m_W1Idx = 0;
    int m_W2Idx = 0;
    int m_Y1Idx = 0;
    int m_Y2Idx = 0;
    int m_P1Idx = 0;
    int m_P2Idx = 0;
    int m_R1Idx = 0;
    int m_R2Idx = 0;
    bool m_IsRight = true; // left if false

    vec3 m_CenterPos;
    // direction of road at pos1 (reversed if left)
    CGameCtnAnchoredObject::ECardinalDirections m_BlockDirection = CGameCtnAnchoredObject::ECardinalDirections::North;

    CGameCtnAnchoredObject@ m_OriginalBlock;

    //--------------------------------------------------------------------------------
    bool FromName(const string &in iName, CGameCtnAnchoredObject::ECardinalDirections iDir, bool iIsRight = true)
    {
        array<string> roadProperties = iName.Split("_");

        if(roadProperties.Length != 5)
        {
            warn("Unknown road name format");
            return false;
        }

        bool success = false;
        m_SurfaceIdx = FindIdx(roadProperties[0], s_Surfaces, true, success);
        if(!success)
            return false;

        if(!FindIdxPair(roadProperties[1], m_W1Idx, m_W2Idx, s_WidthValues))
            return false;
        if(!FindIdxPair(roadProperties[2], m_Y1Idx, m_Y2Idx, s_YawValues))
            return false;
        if(!FindIdxPair(roadProperties[3], m_P1Idx, m_P2Idx, s_PitchValues))
            return false;
        if(!FindIdxPair(roadProperties[4], m_R1Idx, m_R2Idx, s_RollValues))
            return false;

        m_IsRight = iIsRight;
        m_BlockDirection = iDir;

        return true;
    }
  
    //--------------------------------------------------------------------------------
    bool FromAo(CGameCtnAnchoredObject@ iAo, bool iIsRight = true)
    {
        if(iAo is null)
            return false;
        if(iAo.ItemModel is null)
            return false;

        if(!FromName(iAo.ItemModel.Name, YawToDir(iAo.Yaw), iIsRight))
            return false;

        m_CenterPos = iAo.AbsolutePositionInMap;
        @m_OriginalBlock = @iAo;

        return true;
    }

    //--------------------------------------------------------------------------------
    string ToString()
    {
        return s_Surfaces[m_SurfaceIdx] + "_" + BuildPair(s_WidthValues, m_W1Idx, m_W2Idx) + "_"
        + BuildPair(s_YawValues, m_Y1Idx, m_Y2Idx) + "_" + BuildPair(s_PitchValues, m_P1Idx, m_P2Idx) + "_"
        + BuildPair(s_RollValues, m_R1Idx, m_R2Idx);
    }

    //--------------------------------------------------------------------------------
    bool PlaceRoad()
    {
        bool doReplace = m_OriginalBlock !is null;

        CGameCtnAnchoredObject@ ao = @m_OriginalBlock;
        if(ao is null)
        {
            CGameCtnChallenge@ map = GetMap();
            if(map is null)
                return false;

            if(map.AnchoredObjects.Length <= 0)
            {
                warn("Can't place block when map is empty.");
                return false;
            }

            @ao = map.AnchoredObjects[0];
        }

        string roadName = ToString();
        CGameItemModel@ roadModel = CustomEditor::FindItemByName(roadName);
        if(roadModel is null)
        {
            error("Could not find road \"" + roadName + "\"");
            return false;
        }

        CGameItemModel@ modelBackup = ao.ItemModel;

        Editor::SetAO_ItemModel(ao, roadModel);
        Editor::ItemSpec@ itemSpec = Editor::MakeItemSpec(ao);
        itemSpec.name = roadName;
        itemSpec.pos = m_CenterPos + s_ItemSpecPosDelta;
        itemSpec.pyr = vec3(0, DirToYaw(m_BlockDirection), 0);

        // need to restore model
        Editor::SetAO_ItemModel(ao, modelBackup);
        if(doReplace)
        {
            array<CGameCtnAnchoredObject@> aos = {m_OriginalBlock};
            Editor::DeleteItems(aos);
        }

        array<Editor::ItemSpec@> itemsSpec = {itemSpec};
        Editor::PlaceItems(itemsSpec, true);
        print("Placed \"" + roadName + "\"");

        CGameCtnChallenge@ map = GetMap();
        if(map is null)
            error("No map found");
        else
            @m_OriginalBlock = map.AnchoredObjects[map.AnchoredObjects.Length - 1];

        return true;
    }

    //--------------------------------------------------------------------------------
    void Fix()
    {
        m_SurfaceIdx = Math::Clamp(m_SurfaceIdx, 0, s_Surfaces.Length - 1);
        m_W1Idx = Math::Clamp(m_W1Idx, 0, s_WidthValues.Length - 1);
        m_W2Idx = Math::Clamp(m_W2Idx, 0, s_WidthValues.Length - 1);
        m_Y1Idx = Math::Clamp(m_Y1Idx, 0, s_YawValues.Length - 2);
        m_Y2Idx = Math::Clamp(m_Y2Idx, 0, s_YawValues.Length - 1);
        m_P1Idx = Math::Clamp(m_P1Idx, 0, s_PitchValues.Length - 1);
        m_P2Idx = Math::Clamp(m_P2Idx, 0, s_PitchValues.Length - 1);
        if(m_IsRight)
            m_P2Idx = Math::Clamp(m_P2Idx, m_P1Idx - s_MaxPitchIdxDelta, m_P1Idx + s_MaxPitchIdxDelta);
        else
            m_P1Idx = Math::Clamp(m_P1Idx, m_P2Idx - s_MaxPitchIdxDelta, m_P2Idx + s_MaxPitchIdxDelta);
        m_R1Idx = Math::Clamp(m_R1Idx, 0, s_RollValues.Length - 1);
        m_R2Idx = Math::Clamp(m_R2Idx, 0, s_RollValues.Length - 1);
        if(m_IsRight)
            m_R2Idx = Math::Clamp(m_R2Idx, m_R1Idx - s_MaxRollIdxDelta, m_R1Idx + s_MaxRollIdxDelta);
        else
            m_R1Idx = Math::Clamp(m_R1Idx, m_R2Idx - s_MaxRollIdxDelta, m_R2Idx + s_MaxRollIdxDelta);
    }

    //--------------------------------------------------------------------------------
    // Transform right turn into a left one or vice-versa
    void Mirror()
    {
        int tmp = m_W1Idx;
        m_W1Idx = m_W2Idx;
        m_W2Idx = tmp;

        int transformedYawIdx = s_TransformingYawIdx[m_Y1Idx];
        if(m_IsRight)
            transformedYawIdx += m_Y2Idx;
        else
            transformedYawIdx -= m_Y2Idx;

        bool isOpposite = true;
        if(transformedYawIdx < 0)
        {
            transformedYawIdx += s_TransformingYawIdx.Length;
            isOpposite = false;
        }
        if(transformedYawIdx >= int(s_TransformingYawIdx.Length))
        {
            transformedYawIdx -= s_TransformingYawIdx.Length;
            isOpposite = false;
        }

        m_Y1Idx = s_TransformingYawIdx.Find(transformedYawIdx);

        if(isOpposite)
            m_BlockDirection = Opposite(m_BlockDirection);
        else
        {
            if(m_IsRight)
                m_BlockDirection = RotateCounterCw(m_BlockDirection);
            else
                m_BlockDirection = RotateCw(m_BlockDirection);
        }

        tmp = s_PitchValues.Length - m_P1Idx - 1;
        m_P1Idx = s_PitchValues.Length - m_P2Idx - 1;
        m_P2Idx = tmp;

        tmp = s_RollValues.Length - m_R1Idx - 1;
        m_R1Idx = s_RollValues.Length - m_R2Idx - 1;
        m_R2Idx = tmp;

        m_IsRight = !m_IsRight;
    }

    //--------------------------------------------------------------------------------
    vec3 LocalToWorld(const vec3 &in iPos)
    {
        return GetRotationMatrix(m_BlockDirection) * iPos + m_CenterPos;
    }

    //--------------------------------------------------------------------------------
    vec3 WorldToLocal(const vec3 &in iPos)
    {
        return GetRotationMatrix(Inverse(m_BlockDirection)) * (iPos - m_CenterPos);
    }

    //--------------------------------------------------------------------------------
    vec3 GetPos1()
    {
        return LocalToWorld(vec3(16, s_YDelta[m_P1Idx], -s_XZDelta[s_TransformingYawIdx[m_Y1Idx]]));
    }

    //--------------------------------------------------------------------------------
    vec3 GetPos2()
    {
        float yVal = s_YDelta[s_YDelta.Length - 1 - m_P2Idx];

        int xzDeltaIdx = s_TransformingYawIdx[m_Y1Idx];
        xzDeltaIdx += s_YawValues.Length - 1 - m_Y2Idx;
        if(xzDeltaIdx < int(s_XZDelta.Length))
            return LocalToWorld(vec3(-s_XZDelta[xzDeltaIdx], yVal, -16));
        else
            return LocalToWorld(vec3(-16, yVal, s_XZDelta[xzDeltaIdx - s_XZDelta.Length]));
    }

    //--------------------------------------------------------------------------------
    vec3 GetStartPos()
    {
        return m_IsRight ? GetPos1() : GetPos2();
    }

    //--------------------------------------------------------------------------------
    vec3 GetEndPos()
    {
        return m_IsRight ? GetPos2() : GetPos1();
    }

    //--------------------------------------------------------------------------------
    void SetStartPos(const vec3 &in iPos)
    {
        vec3 oldPos = GetStartPos();
        vec3 delta = iPos - oldPos;
        m_CenterPos += delta;
    }
    
    //--------------------------------------------------------------------------------
    void SetEndPos(const vec3 &in iPos)
    {
        vec3 oldPos = GetEndPos();
        vec3 delta = iPos - oldPos;
        m_CenterPos += delta;
    }

    //--------------------------------------------------------------------------------
    RoadItem GetNextRoad()
    {
        RoadItem nextRoad;
        nextRoad = this;
        @nextRoad.m_OriginalBlock = null;

        int transformedYawIdx = s_TransformingYawIdx[nextRoad.m_Y1Idx];
        if(nextRoad.m_IsRight)
        {
            transformedYawIdx -= nextRoad.m_Y2Idx;
            if(transformedYawIdx < 0)
            {
                nextRoad.m_BlockDirection = RotateCounterCw(nextRoad.m_BlockDirection);
                transformedYawIdx += s_TransformingYawIdx.Length;
            }

            nextRoad.m_W1Idx = nextRoad.m_W2Idx;
            nextRoad.m_P1Idx = nextRoad.m_P2Idx;
            nextRoad.m_R1Idx = nextRoad.m_R2Idx;
        }
        else
        {
            transformedYawIdx += nextRoad.m_Y2Idx;
            if(transformedYawIdx >= int(s_TransformingYawIdx.Length))
            {
                nextRoad.m_BlockDirection = RotateCw(nextRoad.m_BlockDirection);
                transformedYawIdx -= s_TransformingYawIdx.Length;
            }

            nextRoad.m_W2Idx = nextRoad.m_W1Idx;
            nextRoad.m_P2Idx = nextRoad.m_P1Idx;
            nextRoad.m_R2Idx = nextRoad.m_R1Idx;
        }
        nextRoad.m_Y1Idx = s_TransformingYawIdx.Find(transformedYawIdx);

        nextRoad.SetStartPos(GetEndPos());

        return nextRoad;
    }
}

//--------------------------------------------------------------------------------
string BuildPair(const array<int> &in iVal, int iIdx1, int iIdx2)
{
    return iVal[iIdx1] + ";" + iVal[iIdx2];
}

//--------------------------------------------------------------------------------
int FindIdx(const string &in iVal, array<string> &inout ioEntries, bool iDoInsert = false, bool &out oSuccess = false)
{
    int foundIdx = ioEntries.Find(iVal);
    if(foundIdx < 0)
    {
        if(!iDoInsert)
        {
            warn("\"" + iVal + "\" was not found");
            oSuccess = false;
            return 0;
        }

        ioEntries.InsertLast(iVal);
        oSuccess = true;
        return ioEntries.Length - 1;
    }

    oSuccess = true;
    return foundIdx;
}

//--------------------------------------------------------------------------------
int FindIdx(int iVal, array<int> &inout ioEntries, bool iDoInsert = false, bool &out oSuccess = false)
{
    int foundIdx = ioEntries.Find(iVal);
    if(foundIdx < 0)
    {
        if(!iDoInsert)
        {
            warn("\"" + iVal + "\" was not found");
            oSuccess = false;
            return 0;
        }

        ioEntries.InsertLast(iVal);
        oSuccess = true;
        return ioEntries.Length - 1;
    }

    oSuccess = true;
    return foundIdx;
}

//--------------------------------------------------------------------------------
bool FindIdxPair(const string &in iVal, int &out oVal1, int &out oVal2, array<int> &inout ioEntries, bool iDoInsert = false)
{
    array<string> pair = iVal.Split(";");

    if(pair.Length != 2)
    {
        warn("Unknown road name format");
        oVal1 = 0;
        oVal2 = 0;
        return false;
    }

    bool success1 = false;
    oVal1 = FindIdx( Text::ParseInt(pair[0]), ioEntries, iDoInsert, success1);
    bool success2 = false;
    oVal2 = FindIdx( Text::ParseInt(pair[1]), ioEntries, iDoInsert, success2);

    return success1 && success2;
}

//--------------------------------------------------------------------------------
CGameCtnAnchoredObject::ECardinalDirections RotateCw(CGameCtnAnchoredObject::ECardinalDirections iDir)
{
    switch(iDir)
    {
        case CGameCtnAnchoredObject::ECardinalDirections::North:
            return CGameCtnAnchoredObject::ECardinalDirections::East;
        case CGameCtnAnchoredObject::ECardinalDirections::East:
            return CGameCtnAnchoredObject::ECardinalDirections::South;
        case CGameCtnAnchoredObject::ECardinalDirections::South:
            return CGameCtnAnchoredObject::ECardinalDirections::West;
        case CGameCtnAnchoredObject::ECardinalDirections::West:
            return CGameCtnAnchoredObject::ECardinalDirections::North;
        default:
            return CGameCtnAnchoredObject::ECardinalDirections::North;
    }
}

//--------------------------------------------------------------------------------
CGameCtnAnchoredObject::ECardinalDirections RotateCounterCw(CGameCtnAnchoredObject::ECardinalDirections iDir)
{
    switch(iDir)
    {
        case CGameCtnAnchoredObject::ECardinalDirections::North:
            return CGameCtnAnchoredObject::ECardinalDirections::West;
        case CGameCtnAnchoredObject::ECardinalDirections::East:
            return CGameCtnAnchoredObject::ECardinalDirections::North;
        case CGameCtnAnchoredObject::ECardinalDirections::South:
            return CGameCtnAnchoredObject::ECardinalDirections::East;
        case CGameCtnAnchoredObject::ECardinalDirections::West:
            return CGameCtnAnchoredObject::ECardinalDirections::South;
        default:
            return CGameCtnAnchoredObject::ECardinalDirections::North;
    }
}

//--------------------------------------------------------------------------------
CGameCtnAnchoredObject::ECardinalDirections Opposite(CGameCtnAnchoredObject::ECardinalDirections iDir)
{
    switch(iDir)
    {
        case CGameCtnAnchoredObject::ECardinalDirections::North:
            return CGameCtnAnchoredObject::ECardinalDirections::South;
        case CGameCtnAnchoredObject::ECardinalDirections::East:
            return CGameCtnAnchoredObject::ECardinalDirections::West;
        case CGameCtnAnchoredObject::ECardinalDirections::South:
            return CGameCtnAnchoredObject::ECardinalDirections::North;
        case CGameCtnAnchoredObject::ECardinalDirections::West:
            return CGameCtnAnchoredObject::ECardinalDirections::East;
        default:
            return CGameCtnAnchoredObject::ECardinalDirections::North;
    }
}

//--------------------------------------------------------------------------------
CGameCtnAnchoredObject::ECardinalDirections Inverse(CGameCtnAnchoredObject::ECardinalDirections iDir)
{
    switch(iDir)
    {
        case CGameCtnAnchoredObject::ECardinalDirections::North:
            return CGameCtnAnchoredObject::ECardinalDirections::South;
        case CGameCtnAnchoredObject::ECardinalDirections::East:
            return CGameCtnAnchoredObject::ECardinalDirections::East;
        case CGameCtnAnchoredObject::ECardinalDirections::South:
            return CGameCtnAnchoredObject::ECardinalDirections::North;
        case CGameCtnAnchoredObject::ECardinalDirections::West:
            return CGameCtnAnchoredObject::ECardinalDirections::West;
        default:
            return CGameCtnAnchoredObject::ECardinalDirections::West;
    }
}

//--------------------------------------------------------------------------------
CGameCtnAnchoredObject::ECardinalDirections YawToDir(float iYaw)
{
    float yaw = iYaw;
    while(yaw < -Math::PI)
        yaw += s_2PI;
    while(yaw >= Math::PI)
        yaw -= s_2PI;

    if(yaw < -s_3PI_4)
        return CGameCtnAnchoredObject::ECardinalDirections::South;
    
    if(-s_3PI_4 <= yaw && yaw < -s_PI_4)
        return CGameCtnAnchoredObject::ECardinalDirections::West;

    if(-s_PI_4 <= yaw && yaw < s_PI_4)
        return CGameCtnAnchoredObject::ECardinalDirections::North;

    if(s_PI_4 <= yaw && yaw < s_3PI_4)
        return CGameCtnAnchoredObject::ECardinalDirections::East;

    return CGameCtnAnchoredObject::ECardinalDirections::South;
}

//--------------------------------------------------------------------------------
float DirToYaw(CGameCtnAnchoredObject::ECardinalDirections iDir)
{
    switch(iDir)
    {
        case CGameCtnAnchoredObject::ECardinalDirections::North:
            return 0;
        case CGameCtnAnchoredObject::ECardinalDirections::East:
            return s_PI_2;
        case CGameCtnAnchoredObject::ECardinalDirections::South:
            return -Math::PI;
        case CGameCtnAnchoredObject::ECardinalDirections::West:
            return -s_PI_2;
        default:
            return 0;
    }
}

//--------------------------------------------------------------------------------
mat3 GetRotationMatrix(CGameCtnAnchoredObject::ECardinalDirections iDir)
{
    int cosVal = 1;
    int sinVal = 0;
    switch(iDir)
    {
        case CGameCtnAnchoredObject::ECardinalDirections::West:
            cosVal = 1;
            sinVal = 0;
            break;
        case CGameCtnAnchoredObject::ECardinalDirections::North:
            cosVal = 0;
            sinVal = -1;
            break;
        case CGameCtnAnchoredObject::ECardinalDirections::East:
            cosVal = -1;
            sinVal = 0;
            break;
        case CGameCtnAnchoredObject::ECardinalDirections::South:
            cosVal = 0;
            sinVal = 1;
            break;
    }

    return mat3(vec3(cosVal, 0, sinVal), vec3(0, 1, 0), vec3(-sinVal, 0, cosVal));
}