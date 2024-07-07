//--------------------------------------------------------------------------------
void DisplayUI()
{
    if(currentRoad is null)
        return;

    if(UI::Begin("Road settings", UI::WindowFlags::AlwaysAutoResize))
    {
        bool hasChanged = false;

        currentRoad.m_SurfaceIdx = RenderIdxRangeButton(hasChanged, hasChanged, "Surface", currentRoad.m_SurfaceIdx, s_Surfaces);

        UI::Separator();

        if(previousRoad is null)
        {
            currentRoad.m_W1Idx = RenderIdxRangeButton(hasChanged, hasChanged, "Width 1", currentRoad.m_W1Idx, s_WidthValues);
            currentRoad.m_Y1Idx = RenderIdxRangeButton(hasChanged, hasChanged, "Yaw 1", currentRoad.m_Y1Idx, s_Yaw1Values);
            currentRoad.m_P1Idx = RenderIdxRangeButton(hasChanged, hasChanged, "Pitch 1", currentRoad.m_P1Idx, s_PitchValues);
            currentRoad.m_R1Idx = RenderIdxRangeButton(hasChanged, hasChanged, "Roll 1", currentRoad.m_R1Idx, s_RollValues);

            UI::Separator();

            currentRoad.m_W2Idx = RenderIdxRangeButton(hasChanged, hasChanged, "Width 2", currentRoad.m_W2Idx, s_WidthValues);
            currentRoad.m_Y2Idx = RenderIdxRangeButton(hasChanged, hasChanged, "Yaw 2", currentRoad.m_Y2Idx, s_YawValues, false);
            currentRoad.m_P2Idx = RenderIdxRangeButton(hasChanged, hasChanged, "Pitch 2", currentRoad.m_P2Idx, s_PitchValues, false);
            currentRoad.m_R2Idx = RenderIdxRangeButton(hasChanged, hasChanged, "Roll 2", currentRoad.m_R2Idx, s_RollValues, false);
        }
        else
        {
            if(currentRoad.m_IsRight)
            {
                currentRoad.m_W2Idx = RenderIdxRangeButton(hasChanged, hasChanged, "Width 2", currentRoad.m_W2Idx, s_WidthValues);
                currentRoad.m_Y2Idx = RenderIdxRangeButton(hasChanged, hasChanged, "Yaw 2", currentRoad.m_Y2Idx, s_YawValues, false);
                currentRoad.m_P2Idx = RenderIdxRangeButton(hasChanged, hasChanged, "Pitch 2", currentRoad.m_P2Idx, s_PitchValues, false);
                currentRoad.m_R2Idx = RenderIdxRangeButton(hasChanged, hasChanged, "Roll 2", currentRoad.m_R2Idx, s_RollValues, false);
            }
            else
            {
                currentRoad.m_W1Idx = RenderIdxRangeButton(hasChanged, hasChanged, "Width 2", currentRoad.m_W1Idx, s_WidthValues);

                bool hasYChanged = false;
                int newYIdx = RenderIdxRangeButton(hasYChanged, hasYChanged, "Yaw 2", currentRoad.m_Y2Idx, s_YawValues);
                if(hasYChanged)
                {
                    hasChanged = true;
                    currentRoad.Mirror();
                    currentRoad.m_Y2Idx = newYIdx;
                    currentRoad.Mirror();
                }

                currentRoad.m_P1Idx = s_PitchValues.Length - RenderIdxRangeButton(hasChanged, hasChanged, "Pitch 2", s_PitchValues.Length - currentRoad.m_P1Idx - 1, s_PitchValues) - 1;
                currentRoad.m_R1Idx = s_RollValues.Length - RenderIdxRangeButton(hasChanged, hasChanged, "Roll 2", s_RollValues.Length - currentRoad.m_R1Idx - 1, s_RollValues) - 1;
            }
        }

        UI::Separator();

        if(hasChanged)
            currentRoad.Fix();

        if(previousRoad !is null)
        {
            if(UI::Button("Mirror"))
            {
                currentRoad.Mirror();
                hasChanged = true;
            }
        }

        if(hasChanged)
        {
            if(previousRoad !is null)
                currentRoad.SetStartPos(previousRoad.GetEndPos());
            currentRoad.PlaceRoad();
        }
        
        UI::SameLine();
        if(UI::Button("End"))
            EndPlacement();
    }
    UI::End();
}

//--------------------------------------------------------------------------------
// return if clicked
bool DrawPoint(const vec3 &in iPos, const vec4 &in iColor)
{
    vec2 pos2d = Camera::ToScreenSpace(iPos);

    UI::SetNextWindowPos(int(pos2d.x), int(pos2d.y), UI::Cond::Always, 0.5f, 0.5f);
    UI::SetNextWindowContentSize(s_PointRadii * 2, s_PointRadii * 2);
    UI::SetNextWindowSize(s_PointRadii * 2, s_PointRadii * 2, UI::Cond::Appearing);
    UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(0,0));
    UI::PushStyleVar(UI::StyleVar::WindowMinSize, vec2(0,0));

    UI::PushStyleColor(UI::Col::WindowBg, s_Transparent);

    bool isClicked = false;
    if(UI::Begin(iPos.x + ";" + iPos.y + ";" + iPos.z, s_PointWindowFlags))
    {
        UI::PushStyleVar(UI::StyleVar::FrameRounding, s_PointRadii);
        UI::PushStyleColor(UI::Col::Button, iColor);
        isClicked = UI::Button("##", vec2(s_PointRadii * 2, s_PointRadii * 2));
        UI::PopStyleColor();
        UI::PopStyleVar();
    }
    UI::End();

    UI::PopStyleColor();
    UI::PopStyleVar(2);

    return isClicked;
}

//--------------------------------------------------------------------------------
void RenderGizmos()
{
    if(currentRoad is null)
        return;

    bool goNextRoad = false;
    if(previousRoad is null)
    {
        if(DrawPoint(currentRoad.GetPos1(), s_Blue))
        {
            currentRoad.m_IsRight = false;
            goNextRoad = true;
        }
        if(DrawPoint(currentRoad.GetPos2(), s_Red))
        {
            currentRoad.m_IsRight = true;
            goNextRoad = true;
        }

    }
    else if(DrawPoint(currentRoad.GetEndPos(), currentRoad.m_IsRight ? s_Red : s_Blue))
        goNextRoad = true;

    if(goNextRoad)
        NextPlacement();
}

//--------------------------------------------------------------------------------
int RenderIdxRangeButton(bool oInitHasChanged, bool &out oHasChanged, const string &in iLabel, int iIdx, const string[] &in iValues, bool iDoLoop = true)
{
    oHasChanged = oInitHasChanged;
    int idx = iIdx;

    UI::PushID(iLabel);
    if(UI::Button("<-"))
    {
        oHasChanged = true;
        idx--;
    }
    vec4 buttonRect = UI::GetItemRect();
    UI::SameLine();
    UI::Text(iLabel + ": " + iValues[iIdx]);
    vec4 textRect = UI::GetItemRect();
    UI::SameLine();
    UI::Dummy(vec2(s_MaxWindowWidth - buttonRect.z * 2 - textRect.z, buttonRect.w));
    UI::SameLine();
    if(UI::Button("->"))
    {
        oHasChanged = true;
        idx++;
    }
    UI::PopID();

    return FixIdx(idx, iValues.Length, iDoLoop);
}

//--------------------------------------------------------------------------------
int RenderIdxRangeButton(bool oInitHasChanged, bool &out oHasChanged, const string &in iLabel, int iIdx, const int[] &in iValues, bool iDoLoop = true)
{
    oHasChanged = oInitHasChanged;
    int idx = iIdx;

    UI::PushID(iLabel);
    if(UI::Button("-"))
    {
        oHasChanged = true;
        idx--;
    }
    vec4 buttonRect = UI::GetItemRect();
    UI::SameLine();
    UI::Text(iLabel + ": " + iValues[iIdx]);
    vec4 textRect = UI::GetItemRect();
    UI::SameLine();
    UI::Dummy(vec2(s_MaxWindowWidth - buttonRect.z * 2 - textRect.z, buttonRect.w));
    UI::SameLine();
    if(UI::Button("+"))
    {
        oHasChanged = true;
        idx++;
    }
    UI::PopID();

    return FixIdx(idx, iValues.Length, iDoLoop);
}

//--------------------------------------------------------------------------------
int FixIdx(int iIdx, int iArrayLength, bool iDoLoop = true)
{
    if(iIdx < 0)
        return (iDoLoop ? iArrayLength - 1 : 0);
    if(iIdx >= iArrayLength)
        return (iDoLoop ? 0 : iArrayLength - 1);
    return iIdx;
}