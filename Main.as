[Setting]
bool s_IsEnabled = true;

RoadItem@ currentRoad;
RoadItem@ previousRoad;

//--------------------------------------------------------------------------------
void SetEnabled(bool iIsEnabled)
{
    s_IsEnabled = iIsEnabled;
    if(!s_IsEnabled)
    {
        @currentRoad = null;
        @previousRoad = null;
    }
}

//--------------------------------------------------------------------------------
void Main() {}

bool wasPicking = false;
//--------------------------------------------------------------------------------
void Update(float iDeltaTime)
{
    if(!s_IsEnabled)
        return;

    CGameCtnEditorFree@ editor = GetEditor();
    if(editor is null)
    {
        SetEnabled(false);
        return;
    }
    CGameEditorPluginMapMapType@ pluginMap = editor.PluginMapType;
    if(pluginMap is null)
    {
        SetEnabled(false);
        return;
    }

    if(wasPicking)
    {
        if(pluginMap.PlaceMode == CGameEditorPluginMap::EPlaceMode::Item && pluginMap.EditMode == CGameEditorPluginMap::EditMode::Pick)
            return; // still picking

        wasPicking = false;
        
        if(editor.PickedObject is null)
            return;
        
        InitPlacementWith(editor.PickedObject);
    }
    else
    {
        if(pluginMap.PlaceMode == CGameEditorPluginMap::EPlaceMode::Item && pluginMap.EditMode == CGameEditorPluginMap::EditMode::Pick)
            wasPicking = true;
    }

    
}

//--------------------------------------------------------------------------------
void RenderInterface()
{
    if(!IsValidState())
        return;

    DisplayUI();

    RenderGizmos();
}

//--------------------------------------------------------------------------------
bool IsValidState()
{
    if(!s_IsEnabled)
        return false;

    CGameCtnChallenge@ map = GetMap();
    if(map is null)
    {
        SetEnabled(false);
        return false;
    }

    return true;
}

//--------------------------------------------------------------------------------
CGameCtnEditorFree@ GetEditor()
{
    CGameCtnApp@ app = GetApp();
    if(app is null)
        return null;

    return cast<CGameCtnEditorFree>(app.Editor);
}

//--------------------------------------------------------------------------------
CGameEditorPluginMapMapType@ GetPluginMap()
{
    CGameCtnEditorFree@ editor = GetEditor();
    if(editor is null)
        return null;

    return editor.PluginMapType;
}

//--------------------------------------------------------------------------------
CGameCtnChallenge@ GetMap()
{
    CGameEditorPluginMapMapType@ pluginMap = GetPluginMap();
    if(pluginMap is null)
        return null;
    
    return pluginMap.Map;
}

bool wasInventoryShown = false;
//--------------------------------------------------------------------------------
void InitPlacementWith(CGameCtnAnchoredObject@ iAo)
{
    RoadItem pickedRoad;
    if(!pickedRoad.FromAo(iAo))
        return;

    @currentRoad = @pickedRoad;

    CGameEditorPluginMapMapType@ pluginMap = GetPluginMap();
    if(pluginMap !is null)
    {
        pluginMap.EditMode = CGameEditorPluginMap::EditMode::FreeLook;
        wasInventoryShown = pluginMap.HideInventory;
        pluginMap.HideInventory = false;
    }
}

//--------------------------------------------------------------------------------
void NextPlacement()
{
    @previousRoad = @currentRoad;
    @currentRoad = previousRoad.GetNextRoad();
    currentRoad.PlaceRoad();
}

//--------------------------------------------------------------------------------
void EndPlacement()
{
    @currentRoad = null;
    @previousRoad = null;

    CGameEditorPluginMapMapType@ pluginMap = GetPluginMap();
    if(pluginMap !is null)
    {
        pluginMap.PlaceMode = CGameEditorPluginMap::EPlaceMode::Item;
        pluginMap.EditMode = CGameEditorPluginMap::EditMode::Place;
        pluginMap.HideInventory = pluginMap.HideInventory || wasInventoryShown;
    }
}

//--------------------------------------------------------------------------------
namespace CustomEditor
{
    //--------------------------------------------------------------------------------
    // find an item and do not yield
    CGameItemModel@ FindItemByName(const string &in iName)
    {
        CGameCtnChapter@ itemsCatalog = GetApp().GlobalCatalog.Chapters[3];
        for(int ii = itemsCatalog.Articles.Length - 1; ii > 1; ii--)
        {
            CGameCtnArticle@ item = itemsCatalog.Articles[ii];
            if(item.Name == iName)
            {
                if(item.LoadedNod is null)
                    item.Preload();
                return cast<CGameItemModel>(item.LoadedNod);
            }
        }
        return null;
    }
}