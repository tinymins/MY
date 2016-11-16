void KItemHandleClassScriptTable::Load(lua_State* L)
{
    static luaL_reg const s_aItemNullMetaTable[] =
    {
        { "SetVisible",						LuaItemNull_SetVisible},
        { "Show",							LuaItemNull_Show},
        { "Hide",							LuaItemNull_Hide},
        { "PtInItem",						LuaItemNull_PtInItem},
        { "IsMouseIn",						LuaItemNull_IsMouseIn},
        { "SetMouseButtonStatusElement",	LuaItemNull_SetMouseButtonStatusElement},
        { "ClearMouseButtonStatusElement",	LuaItemNull_ClearMouseButtonStatusElement},
        { "SetHoverElement",				LuaItemNull_SetHoverElement},
        { "ClearHoverElement",				LuaItemNull_ClearHoverElement},

        { "SetRelX",						LuaItemNull_SetRelX},
        { "SetRelY",						LuaItemNull_SetRelY},

        { "GetRelX",						LuaItemNull_GetRelX},
        { "GetRelY",						LuaItemNull_GetRelY},

        { "SetAbsX",						LuaItemNull_SetAbsX},
        { "SetAbsY",						LuaItemNull_SetAbsY},

        { "GetAbsX",						LuaItemNull_GetAbsX},
        { "GetAbsY",						LuaItemNull_GetAbsY},

        { "SetW",						    LuaItemNull_SetW},
        { "SetH",						    LuaItemNull_SetH},

        { "GetW",						    LuaItemNull_GetW},
        { "GetH",						    LuaItemNull_GetH},

        { "SetRelPos",						LuaItemNull_SetRelPos},
        { "GetRelPos",						LuaItemNull_GetRelPos},
        { "SetAbsPos",						LuaItemNull_SetAbsPos},
        { "GetAbsPos",						LuaItemNull_GetAbsPos},
        { "SetSize",						LuaItemNull_SetSize},
        { "GetSize",						LuaItemNull_GetSize},
        { "SetPosType",						LuaItemNull_SetPosType},
        { "GetPosType",						LuaItemNull_GetPosType},
        { "IsVisible",						LuaItemNull_IsVisible},
        { "GetName",						LuaItemNull_GetName},
        { "SetName",						LuaItemNull_SetName},
        { "SetTip",							LuaItemNull_SetTip},
        { "GetTip",							LuaItemNull_GetTip},
        { "SetUserData",					LuaItemNull_SetUserData},
        { "GetUserData",					LuaItemNull_GetUserData},
        { "RegisterEvent",					LuaItemNull_RegisterEvent},
        { "ClearEvent",						LuaItemNull_ClearEvent},
        { "EnableScale",					LuaItemNull_EnableScale},
        { "Scale",							LuaItemNull_Scale},
        { "LockShowAndHide",				LuaItemNull_LockShowAndHide},
        { "SetAlpha",						LuaItemNull_SetAlpha},
        { "GetAlpha",						LuaItemNull_GetAlpha},
        { "GetParent",						LuaItemNull_GetParent},
        { "GetRoot",						LuaItemNull_GetRoot},
        { "GetType",						LuaItemNull_GetType},
        { "GetIndex",						LuaItemNull_GetIndex},
        { "SetIndex",						LuaItemNull_SetIndex},
        { "ExchangeIndex",					LuaItemNull_ExchangeIndex},
        { "GetTreePath",					LuaItemNull_GetTreePath},
        { "SetAreaTestFile",				LuaItemNull_SetAreaTestFile},
        { "SetIntPos",						LuaItemNull_SetIntPos},
        { "IsIntPos",						LuaItemNull_IsIntPos},
        { "IsLink",                         LuaItemNull_IsLink},
        { "GetLinkInfo",                    LuaItemNull_GetLinkInfo},
        { "SetLinkInfo",                    LuaItemNull_SetLinkInfo},
        { "GetTweenFile",                   LuaItemNull_GetTweenFile},
        { "SetTweenFile",                   LuaItemNull_SetTweenFile},
        { "GetAniParamID" ,                 LuaItemNull_GetAniParamID},
        { "SetPoint",						LuaItemNull_SetPoint },
        { "SetBasicStatus",					LuaItemNull_SetBasicStatus },
        { "ToGray",					        LuaItemNull_ToGray },
        { "ToNormal",					    LuaItemNull_ToNormal },
        { "IsGray",					        LuaItemNull_IsGray },
        { "Lookup",					        LuaItemNull_Lookup },

        { "IsValid",						LuaItemNull_IsValid },
        //		{ "__newindex",						LuaItemNull_NewIndex },
        { "__eq",							LuaItemNull_Equal },
        { "GetBaseType",					LuaItemNull_GetBaseType },

        { NULL,								NULL },
    };

    static luaL_reg const s_aItemTextMetaTable[] =
    {
        //text
        { "SetFontScheme",					LuaItemText_SetFontScheme},
        { "GetFontScheme",					LuaItemText_GetFontScheme},
        { "SetRange",					    LuaItemText_SetRange},
        { "SetTime",					    LuaItemText_SetTime},
        { "SetNumber",					    LuaItemText_SetNumber},
        { "GetNumber",					    LuaItemText_GetNumber},
        { "SprintfText",					LuaItemText_SprintfText},
        { "SetText",						LuaItemText_SetText},
        { "GetText",						LuaItemText_GetText},
        { "GetTextLen",						LuaItemText_GetTextLen},
        { "SetVAlign",						LuaItemText_SetVAlign},
        { "GetVAlign",						LuaItemText_GetVAlign},
        { "SetHAlign",						LuaItemText_SetHAlign},
        { "GetHAlign",						LuaItemText_GetHAlign},
        { "SetRowSpacing",					LuaItemText_SetRowSpacing},
        { "GetRowSpacing",					LuaItemText_GetRowSpacing},
        { "SetMultiLine",					LuaItemText_SetMultiLine},
        { "IsMultiLine",					LuaItemText_IsMultiLine},
        { "FormatTextForDraw",				LuaItemText_FormatTextForDraw},
        { "AutoSize",						LuaItemText_AutoSize},
        { "SetCenterEachLine",				LuaItemText_SetCenterEachLine},
        { "IsCenterEachLine",				LuaItemText_IsCenterEachLine},
        { "SetFontSpacing",					LuaItemText_SetFontSpacing},
        { "GetFontSpacing",					LuaItemText_GetFontSpacing},
        { "SetRichText",					LuaItemText_SetRichText},
        { "IsRichText",						LuaItemText_IsRichText},
        { "GetFontScale",					LuaItemText_GetFontScale},
        { "SetFontScale",					LuaItemText_SetFontScale},
        { "SetFontID",						LuaItemText_SetFontID},
        { "SetFontColor",					LuaItemText_SetFontColor},
        { "SetFontBorder",					LuaItemText_SetFontBoder},
        { "SetFontShadow",					LuaItemText_SetFontShadow},
        { "GetFontID",						LuaItemText_GetFontID},
        { "GetFontColor",					LuaItemText_GetFontColor},
        { "GetFontBoder",					LuaItemText_GetFontBoder},
        { "GetFontProjection",				LuaItemText_GetFontProjection},
        { "GetTextExtent",					LuaItemText_GetTextExtent },
        { "GetTextPosExtent",				LuaItemText_GetTextPosExtent },

        { NULL,								NULL },
    };

    static luaL_reg const s_aItemImageMetaTable[] =
    {
        //image
        { "SetFrame",						LuaItemImage_SetFrame },
        { "GetFrame",						LuaItemImage_GetFrame },
        { "AutoSize",						LuaItemImage_AutoSize },
        { "SetImageType",					LuaItemImage_SetImageType },
        { "GetImageType",					LuaItemImage_GetImageType },
        { "SetPercentage",					LuaItemImage_SetPercentage },
        { "GetPercentage",					LuaItemImage_GetPercentage },
        { "SetRotate",						LuaItemImage_SetRotate },
        { "GetRotate",						LuaItemImage_GetRotate },
        { "GetImageID",						LuaItemImage_GetImageID },
        { "FromUITex",						LuaItemImage_FromUITex },
        { "FromTextureFile",				LuaItemImage_FromTextureFile },
        { "FromRemoteFile",					LuaItemImage_FromRemoteFile },
        { "UnloadSource",				    LuaItemImage_UnloadSource },
        { "FromScene",						LuaItemImage_FromScene},
        { "FromImageID",					LuaItemImage_FromImageID },
        { "FromIconID",						LuaItemImage_FromIconID },
        { "FromWindow",					    LuaItemImage_FromWindow },
        { "FromItem",						LuaItemImage_FromItem },
        { "ToManagedImage",					LuaItemImage_ToManagedImage },
        { "SetPaintOffset",					LuaItemImage_SetPaintOffset },

        { NULL,								NULL },
    };

    static luaL_reg const s_aItemShadowMetaTable[] =
    {
        //shadow
        { "SetShadowColor",					LuaItemShadow_SetShadowColor},
        { "GetShadowColor",					LuaItemShadow_GetShadowColor},
        { "GetColorRGB",					LuaItemShadow_GetColorRGB},
        { "SetColorRGB",					LuaItemShadow_SetColorRGB},
        { "SetD3DPT",					    LuaItemShadow_SetD3DPT},
        { "SetTriangleFan",					LuaItemShadow_SetTriangleFan},
        { "IsTriangleFan",					LuaItemShadow_IsTriangleFan},
        { "AppendDoodadID",			        LuaItemShadow_AppendDoodadID},
        { "AppendCharacterID",			    LuaItemShadow_AppendCharacterID},
        { "AppendTriangleFanPoint",			LuaItemShadow_AppendTriangleFanPoint},
        { "AppendTriangleFan3DPoint",		LuaItemShadow_AppendTriangleFan3DPoint},
        { "ClearTriangleFanPoint",			LuaItemShadow_ClearTriangleFanPoint},
        { "IsInRegion",						LuaItemShadow_IsInRegion},

        { NULL,								NULL },
    };

    static luaL_reg const s_aItemAnimateMetaTable[] =
    {
        //animate
        { "SetGroup",						LuaItemAnimate_SetGroup},
        { "SetLoopCount",					LuaItemAnimate_SetLoopCount},
        { "SetImagePath",					LuaItemAnimate_SetImagePath},
        { "SetAnimate",						LuaItemAnimate_SetAnimate},
        { "AutoSize",						LuaItemAnimate_AutoSize},
        { "Replay",						    LuaItemAnimate_Replay},
        { "SetIdenticalInterval",           LuaItemAnimate_SetIdenticalInterval},
        { "SetInterval",                    LuaItemAnimate_SetInterval},
        { "IsFinished",                     LuaItemAnimate_IsFinished},
        { "SetAnimateType",                 LuaItemAnimate_SetAnimateType},
        { "SetPercentage",                  LuaItemAnimate_SetPercentage},
        { "SetFrame",                       LuaItemAnimate_SetFrame},
        { "EnableReverse",                  LuaItemAnimate_EnableReverse},
        { "IsReverse",                      LuaItemAnimate_IsReverse},

        { NULL,								NULL },
    };

    static luaL_reg const s_aItemSceneMetaTable[] =
    {
        //scene
        { "SetScene",						LuaItemScene_SetScene},
        { "GetScene",						LuaItemScene_GetScene},
        { "EnableRenderTerrain",			LuaItemScene_EnableRenderTerrain},
        { "EnableRenderSkyBox",				LuaItemScene_EnableRenderSkyBox},
        { "EnableAlpha",					LuaItemScene_EnableAlpha},

        { NULL,								NULL },
    };

    static luaL_reg const s_aItemBoxMetaTable[] =
    {
        //box
        { "SetBoxIndex",					LuaItemBox_SetIndex},
        { "GetBoxIndex",					LuaItemBox_GetIndex},
        { "SetObject",						LuaItemBox_SetObject},
        { "GetObject",						LuaItemBox_GetObject},
        { "GetObjectType",					LuaItemBox_GetObjectType},
        { "SetObjectData",					LuaItemBox_SetObjectData},
        { "GetObjectData",					LuaItemBox_GetObjectData},
        { "ClearObject",					LuaItemBox_ClearObject},
        { "Clear",                          LuaItemBox_Clear},
        { "IsEmpty",						LuaItemBox_IsEmpty},
        { "EnableObject",					LuaItemBox_EnableObject},
        { "IsObjectEnable",					LuaItemBox_IsObjectEnable},
        { "EnableObjectEquip",				LuaItemBox_EnableObjectEquip},
        { "IsObjectEquipable",				LuaItemBox_IsObjectEquipable},
        { "SetObjectCoolDown",				LuaItemBox_SetObjectCoolDown},
        { "IsObjectCoolDown",				LuaItemBox_IsObjectCoolDown},
        { "SetObjectSparking",				LuaItemBox_SetObjectSparking},
        { "SetObjectInUse",					LuaItemBox_SetObjectInUse},
        { "SetObjectStaring",				LuaItemBox_SetObjectStaring},
        { "SetObjectSelected",				LuaItemBox_SetObjectSelected},
        { "IsObjectSelected",				LuaItemBox_IsObjectSelected},
        { "SetObjectMouseOver",				LuaItemBox_SetObjectMouseOver},
        { "IsObjectMouseOver",				LuaItemBox_IsObjectMouseOver},
        { "SetObjectPressed",				LuaItemBox_SetObjectPressed},
        { "IsObjectPressed",				LuaItemBox_IsObjectPressed},
        { "SetCoolDownPercentage",			LuaItemBox_SetCoolDownPercentage},
        { "GetCoolDownPercentage",			LuaItemBox_GetCoolDownPercentage},
        { "SetObjectCoolDownType",			LuaItemBox_SetObjectCoolDownType},
        { "SetObjectIcon",					LuaItemBox_SetObjectIcon},
        { "GetObjectIcon",					LuaItemBox_GetObjectIcon},
        { "ClearObjectIcon",				LuaItemBox_ClearObjectIcon},
        { "SetOverText",					LuaItemBox_SetOverText},
        { "GetOverText",					LuaItemBox_GetOverText},
        { "SetOverTextFontScheme",			LuaItemBox_SetOverTextFontScheme},
        { "GetOverTextFontScheme",			LuaItemBox_GetOverTextFontScheme},
        { "SetOverTextPosition",			LuaItemBox_SetOverTextPosition},
        { "GetOverTextPosition",			LuaItemBox_GetOverTextPosition},
        { "SetExtentImage",					LuaItemBox_SetExtentImage},
        { "ClearExtentImage",				LuaItemBox_ClearExtentImage},
        { "SetExtentAnimate",				LuaItemBox_SetExtentAnimate},
        { "ClearExtentAnimate",				LuaItemBox_ClearExtentAnimate},
        { "IsPlayingExAnimate",				LuaItemBox_IsPlayingExAnimate},

        { "SetExtentLayer",					LuaItemBox_SetExtentLayer},
        { "GetExtentLayer",		    		LuaItemBox_GetExtentLayer},
        { "ClearExtentLayer",				LuaItemBox_ClearExtentLayer},
        { "IsExtentAnimatePlaying",			LuaItemBox_IsExtentAnimatePlaying},
        { "SetExtentImageType",				LuaItemBox_SetExtentImageType},
        { "SetExtentAnimateType",			LuaItemBox_SetExtentAnimateType},
        { "GetExtentPercent",				LuaItemBox_GetExtentPercent},
        { "SetExtentPercent",				LuaItemBox_SetExtentPercent},
        { "GetExtentVisible",				LuaItemBox_GetExtentVisible},
        { "SetExtentVisible",				LuaItemBox_SetExtentVisible},
        { "SetExtentTimeStartAngle",		LuaItemBox_SetExtentTimeStartAngle},

        { "IconToGray",				        LuaItemBox_IconToGray},
        { "IconToNormal",			    	LuaItemBox_IconToNormal},
        { "IsIconGray",				        LuaItemBox_IsIconGray},
        { "SetStateResID",				    LuaItemBox_SetStateResID},
        { "ExchangeDrawOrder",				LuaItemBox_ExchangeDrawOrder},

        { NULL,								NULL },
    };

    static luaL_reg const s_aItemHandleMetaTable[] =
    {
        //handle
        { "AppendItemFromString",			LuaItemHandle_AppendItemFromString},
        { "AppendItemFromIni",				LuaItemHandle_AppendItemFromIni},
        { "AdjustItemShowInfo",				LuaItemHandle_AdjustItemShowInfo},
        { "InsertItemFromString",			LuaItemHandle_InsertItemFromString},
        { "InsertItemFromIni",				LuaItemHandle_InsertItemFromIni},
        { "FormatAllItemPos",				LuaItemHandle_FormatAllItemPos},
        { "SetHandleStyle",					LuaItemHandle_SetHandleStyle},
        { "SetMinRowHeight",				LuaItemHandle_SetMinRowHeight},
        { "SetMaxRowHeight",				LuaItemHandle_SetMaxRowHeight},
        { "SetRowHeight",					LuaItemHandle_SetRowHeight},
        { "SetRowSpacing",					LuaItemHandle_SetRowSpacing},
        { "RemoveItem",						LuaItemHandle_RemoveItem},
        { "Clear",							LuaItemHandle_Clear},
        { "GetItemStartRelPos",				LuaItemHandle_GetItemStartRelPos},
        { "SetItemStartRelPos",				LuaItemHandle_SetItemStartRelPos},
        { "SetSizeByAllItemSize",			LuaItemHandle_SetSizeByAllItemSize},
        { "GetAllItemSize",					LuaItemHandle_GetAllItemSize},
        { "GetItemCount",					LuaItemHandle_GetItemCount},
        { "GetVisibleItemCount",			LuaItemHandle_GetVisibleItemCount},
        { "Lookup",							LuaItemHandle_Lookup},
        { "EnableFormatWhenAppend",			LuaItemHandle_EnableFormatWhenAppend},
        { "RemoveItemUntilNewLine",			LuaItemHandle_RemoveItemUntilNewLine},
        { "ExchangeItemIndex",				LuaItemHandle_ExchangeItemIndex},
        { "Sort",							LuaItemHandle_Sort },
        { "AppendItemFromData",				LuaItemHandle_AppendItemFromData },
        { "IsInStencialArea",				LuaItemHandle_IsInStencialArea },
        { "SetVAlign",						LuaItemHandle_SetVAlign},
        { "GetVAlign",						LuaItemHandle_GetVAlign},
        { "SetHAlign",						LuaItemHandle_SetHAlign},
        { "GetHAlign",						LuaItemHandle_GetHAlign},
        { "IsIgnoreInvisibleChild",			LuaItemHandle_IsIgnoreInvisibleChild},
        { "SetIgnoreInvisibleChild",		LuaItemHandle_SetIgnoreInvisibleChild},
        { "LoadShapTexture",				LuaItemHandle_LoadShapTexture},
        { "UnloadShapTexture",				LuaItemHandle_UnloadShapTexture},

        { NULL,								NULL },
    };

    static luaL_reg const s_aItemTreeLeafMetaTable[] =
    {
        //handle
        { "AppendItemFromString",			LuaItemHandle_AppendItemFromString},
        { "AppendItemFromIni",				LuaItemHandle_AppendItemFromIni},
        { "AdjustItemShowInfo",				LuaItemHandle_AdjustItemShowInfo},
        { "InsertItemFromString",			LuaItemHandle_InsertItemFromString},
        { "InsertItemFromIni",				LuaItemHandle_InsertItemFromIni},
        { "FormatAllItemPos",				LuaItemHandle_FormatAllItemPos},
        { "SetHandleStyle",					LuaItemHandle_SetHandleStyle},
        { "SetMinRowHeight",				LuaItemHandle_SetMinRowHeight},
        { "SetMaxRowHeight",				LuaItemHandle_SetMaxRowHeight},
        { "SetRowHeight",					LuaItemHandle_SetRowHeight},
        { "SetRowSpacing",					LuaItemHandle_SetRowSpacing},
        { "RemoveItem",						LuaItemHandle_RemoveItem},
        { "Clear",							LuaItemHandle_Clear},
        { "GetItemStartRelPos",				LuaItemHandle_GetItemStartRelPos},
        { "SetItemStartRelPos",				LuaItemHandle_SetItemStartRelPos},
        { "SetSizeByAllItemSize",			LuaItemHandle_SetSizeByAllItemSize},
        { "GetAllItemSize",					LuaItemHandle_GetAllItemSize},
        { "GetItemCount",					LuaItemHandle_GetItemCount},
        { "GetVisibleItemCount",			LuaItemHandle_GetVisibleItemCount},
        { "Lookup",							LuaItemHandle_Lookup},
        { "EnableFormatWhenAppend",			LuaItemHandle_EnableFormatWhenAppend},
        { "RemoveItemUntilNewLine",			LuaItemHandle_RemoveItemUntilNewLine},
        { "ExchangeItemIndex",				LuaItemHandle_ExchangeItemIndex},
        { "Sort",							LuaItemHandle_Sort },
        { "AppendItemFromData",				LuaItemHandle_AppendItemFromData },

        //treeleaf
        { "IsExpand",						LuaItemTreeLeaf_IsExpand},
        { "ExpandOrCollapse",				LuaItemTreeLeaf_ExpandOrCollapse},
        { "Expand",							LuaItemTreeLeaf_Expand},
        { "Collapse",						LuaItemTreeLeaf_Collapse},
        { "SetIndent",						LuaItemTreeLeaf_SetIndent},
        { "GetIndent",						LuaItemTreeLeaf_GetIndent},
        { "SetEachIndentWidth",				LuaItemTreeLeaf_SetEachIndentWidth},
        { "GetEachIndentWidth",				LuaItemTreeLeaf_GetEachIndentWidth},
        { "SetNodeIconSize",				LuaItemTreeLeaf_SetNodeIconSize},
        { "SetIconImage",					LuaItemTreeLeaf_SetIconImage},
        { "PtInIcon",						LuaItemTreeLeaf_PtInIcon},
        { "AdjustNodeIconPos",				LuaItemTreeLeaf_AdjustNodeIconPos},
        { "AutoSetIconSize",				LuaItemTreeLeaf_AutoSetIconSize},
        { "SetShowIndex",					LuaItemTreeLeaf_SetShowIndex},
        { "GetShowIndex",					LuaItemTreeLeaf_GetShowIndex},

        { NULL,								NULL },
    };

    static luaL_reg const s_aItemSFXMetaTable[] =
    {
        //handle
        { "LoadSFX",			            LuaItemSFX_LoadSFX},
        { "Play",				            LuaItemSFX_Play},
        { "SetModelScale",				    LuaItemSFX_SetModelScale},
        { "GetModelScale",			        LuaItemSFX_GetModelScale},
        { "Get3DModel",				        LuaItemSFX_Get3DModel},
        { "Set2DRotation",                  LuaItemSFX_Set2DRotation},

        { NULL,								NULL },

    };

    int bEnableHook = false;
#ifndef KG_PUBLISH
    bEnableHook = g_pUI->m_Config.m_bEnableRecord;
#endif

    KScriptLoader::RegisterMetaTable(L, g_GetWndItemName(ITEM_NULL), s_aItemNullMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, g_GetWndItemName(ITEM_TEXT), s_aItemNullMetaTable, s_aItemTextMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, g_GetWndItemName(ITEM_IMAGE), s_aItemNullMetaTable, s_aItemImageMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, g_GetWndItemName(ITEM_ANIAMTE), s_aItemNullMetaTable, s_aItemAnimateMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, g_GetWndItemName(ITEM_SHADOW), s_aItemNullMetaTable, s_aItemShadowMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, g_GetWndItemName(ITEM_SCENE), s_aItemNullMetaTable, s_aItemSceneMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, g_GetWndItemName(ITEM_BOX), s_aItemNullMetaTable, s_aItemBoxMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, g_GetWndItemName(ITEM_HANDLE), s_aItemNullMetaTable, s_aItemHandleMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, g_GetWndItemName(ITEM_TREE_LEAFE), s_aItemNullMetaTable, s_aItemTreeLeafMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, g_GetWndItemName(ITEM_SFX), s_aItemNullMetaTable, s_aItemSFXMetaTable, bEnableHook);
}

void KWndClassScriptTable::Load(lua_State* L)
{
    static luaL_reg const s_aCursorLibTable[] =
    {
        { "Show",							LuaCursor_ShowCursor },
        { "IsVisible",						LuaCursor_IsVisible },
        { "Switch",							LuaCursor_SwitchCursor },
        { "GetCurrentIndex",				LuaCursor_GetCurrentCursorIndex },
        { "Restore",						LuaCursor_RestoreCursor },
        { "IsExist",						LuaCursor_IsExistCursor },
        { "Load",							LuaCursor_LoadCursor },
        { "Unload",							LuaCursor_UnloadCursor },
        { "LoadAll",						LuaCursor_LoadAllCursor },
        { "UnloadAll",						LuaCursor_UnloadAllCursor },
        { "GetPos",							LuaCursor_GetCursorPos },
        { "SetPos",							LuaCursor_SetCursorPos },
        { "Enable",							LuaCursor_Enable },

        { NULL,								NULL },
    };

    //--wnd库准备删除。
    static luaL_reg const s_aWndLibTable[] =
    {
        { "ToggleWindow",					LuaStation_ToggleWindow },
        { "OpenWindow",						LuaStation_OpenWindow },
        { "LookupWindow",					LuaStation_LookupWindow },
        { "CloseWindow",					LuaStation_CloseWindow },
        { "KeepInClient",					LuaStation_KeepWndInClient },
        { "SetPopUpMenuPos",				LuaStation_SetPopUpMenuPos },
        { "SetTipPosByRect",				LuaStation_SetTipPosByRect },
        { "SetTipPosByWnd",					LuaStation_SetTipPosByWnd },
        { "AdjustFrameListPosition",		LuaStation_AdjustFrameListPosition },
        { "AssociateImmContext",		    LuaStation_AssociateImmContext },
        { "IsUsingIme",		                LuaStation_IsUsingIme },
        { "GetImeCount",                    LuaStation_GetImeCount },
        { "GetKeyboardLayoutCount",         LuaStation_GetKeyboardLayoutCount },

        { NULL,								NULL },
    };

    static luaL_reg const s_aStationLibTable[] =
    {
        { "SetFocusWindow",					LuaStation_SetFocusWindow },
        { "GetFocusWindow",					LuaStation_GetFocusWindow },
        { "SetActiveFrame",					LuaStation_SetActiveFrame },
        { "GetActiveFrame",					LuaStation_GetActiveFrame },
        { "SetCapture",						LuaStation_SetCapture },
        { "GetCapture",						LuaStation_GetCapture },
        { "ReleaseCapture",					LuaStation_ReleaseCapture },

        { "Lookup",							LuaStation_Lookup },

        { "GetWindowPosition",				LuaStation_GetWindowPosition },
        { "GetClientPosition",				LuaStation_GetClientPosition },

        { "GetStandardClientSize",			LuaStation_GetStandardClientSize },
        { "GetClientSize",					LuaStation_GetClientSize },
        { "OriginalToAdjustPos",			LuaStation_OriginalToAdjustPos },
        { "AdjustToOriginalPos",			LuaStation_AdjustToOriginalPos },
        { "SetUIScale",						LuaStation_SetUIScale },
        { "GetUIScale",						LuaStation_GetUIScale },
        { "GetMaxUIScale",				    LuaStation_GetMaxUIScale },
        { "IsFullScreen",					LuaStation_IsFullScreen },
        { "IsPanauision",					LuaStation_IsPanauision },
        { "IsExclusiveMode",				LuaStation_IsExclusiveMode },
        { "IsVisible",						LuaStation_IsVisible },
        { "Show",							LuaStation_Show },
        { "Hide",							LuaStation_Hide },
        { "Paint",							LuaStation_Paint },
        { "GetScreenPos",					LuaStation_GetScreenPos },
        { "GetMessagePos",					LuaStation_GetMessagePos },
        { "GetMessageWheelDelta",			LuaStation_GetMessageWheelDelta },

        { "GetMessageKey",					LuaStation_GetMessageKey },
        { "GetIdleTime",					LuaStation_GetIdleTime },
        { "ClearIdleTime",					LuaStation_ClearIdleTime },
        { "IsInUserAction",					LuaStation_IsInUserAction },
        { "GetMouseOverWindow",				LuaStation_GetMouseOverWindow},

        { "ToggleWindow",					LuaStation_ToggleWindow },
        { "OpenWindow",						LuaStation_OpenWindow },
        { "CloseWindow",					LuaStation_CloseWindow },
        { "KeepInClient",					LuaStation_KeepWndInClient },
        { "SetPopUpMenuPos",				LuaStation_SetPopUpMenuPos },
        { "SetTipPosByRect",				LuaStation_SetTipPosByRect },
        { "SetTipPosByWnd",					LuaStation_SetTipPosByWnd },
        { "AdjustFrameListPosition",		LuaStation_AdjustFrameListPosition },
        { "RawGetTopFrame",				    LuaStation_RawGetTopFrame },
        { "GetWindowLayer",				    LuaStation_GetWindowLayer },
        { "SearchFrame",				    LuaStation_SearchFrame },

        { NULL,								NULL },
    };

    //-----------------------------------------------------------------------------------------------------------------------
    static luaL_reg const s_aWndWindowMetaTable[] =
    {
        { "SetRelX",						    LuaWindow_SetRelX},
        { "SetRelY",						    LuaWindow_SetRelY},

        { "GetRelX",						    LuaWindow_GetRelX},
        { "GetRelY",						    LuaWindow_GetRelY},

        { "SetAbsX",						    LuaWindow_SetAbsX},
        { "SetAbsY",						    LuaWindow_SetAbsY},

        { "GetAbsX",						    LuaWindow_GetAbsX},
        { "GetAbsY",						    LuaWindow_GetAbsY},

        { "SetW",						        LuaWindow_SetW},
        { "SetH",						        LuaWindow_SetH},

        { "GetW",						        LuaWindow_GetW},
        { "GetH",						        LuaWindow_GetH},

        { "GetRelPos",							LuaWindow_GetRelPos },
        { "GetAbsPos",							LuaWindow_GetAbsPos },
        { "GetSize",							LuaWindow_GetSize },
        { "SetSize",							LuaWindow_SetSize },

        { "IsVisible",							LuaWindow_IsVisible },
        { "IsDisable",							LuaWindow_IsDisable },
        { "SetRelPos",							LuaWindow_SetRelPos },
        { "SetAbsPos",							LuaWindow_SetAbsPos },
        { "SetCursorAbove",						LuaWindow_SetCursorAbove },
        { "Enable",								LuaWindow_Enable },
        { "SetVisible",						    LuaWindow_SetVisible},
        { "Show",								LuaWindow_Show },
        { "Hide",								LuaWindow_Hide },
        { "ToggleVisible",						LuaWindow_ToggleVisible },
        { "BringToTop",							LuaWindow_BringToTop },
        { "Scale",							    LuaWindow_Scale },
        { "CreateItemHandle",					LuaWindow_CreateItemHandle },
        { "ReleaseItemHandle",					LuaWindow_ReleaseItemHandle },
        { "Lookup",							    LuaWindow_Lookup },
        { "GetName",							LuaWindow_GetName },
        { "SetName",							LuaWindow_SetName },
        { "GetPrev",							LuaWindow_GetPrev },
        { "GetNext",							LuaWindow_GetNext },
        { "GetParent",							LuaWindow_GetParent },
        { "GetRoot",							LuaWindow_GetRoot },
        { "GetFirstChild",						LuaWindow_GetFirstChild },
        { "CorrectPos",							LuaWindow_CorrectPos },
        { "IsDummyWnd",							LuaWindow_IsDummyWnd },
        { "SetDummyWnd",						LuaWindow_SetDummyWnd },
        { "IsMousePenetrable",					LuaWindow_IsMousePenetrable },
        { "SetMousePenetrable",					LuaWindow_SetMousePenetrable },
        { "SetAlpha",							LuaWindow_SetAlpha },
        { "SetSelfAlpha",						LuaWindow_SetSelfAlpha },
        { "GetAlpha",							LuaWindow_GetAlpha },
        { "GetType",							LuaWindow_GetType },
        { "ChangeRelation",						LuaWindow_ChangeRelation },
        { "RebuildEventArray",					LuaWindow_RebuildEventArray },
        { "GetIndex",							LuaWindow_GetIndex },
        { "SetIndex",							LuaWindow_SetIndex },
        { "GetChildCount",						LuaWindow_GetChildCount },
        { "SetPoint",							LuaWindow_SetPoint },
        { "SetAreaTestFile",					LuaWindow_SetAreaTestFile },
        { "Destroy",							LuaWindow_Destroy},
        { "GetTreePath",						LuaWindow_GetTreePath },
        { "StartMoving",						LuaWindow_StartMoving },
        { "EndMoving",							LuaWindow_EndMoving },
        { "HasTip",								LuaWindow_HasTip },
        { "IsValid",							LuaWindow_IsValid },
        { "GetBaseType",                        LuaWindow_GetBaseType },
        { "GetAniParamID",                      LuaWindow_GetAniParamID },
        { "PtInWindow",                         LuaWindow_PtInWindow },
        { "IsMouseIn",							LuaWindow_IsMouseIn },
        { "SetBasicStatus",						LuaWindow_SetBasicStatus },


        { "SetMouseButtonStatusElement",		LuaWindow_SetMouseButtonStatusElement },
        { "ClearMouseButtonStatusElement",		LuaWindow_ClearMouseButtonStatusElement },
        { "SetHoverElement",					LuaWindow_SetHoverElement },
        { "ClearHoverElement",					LuaWindow_ClearHoverElement },

        { "GetTweenFile",						LuaWindow_GetTweenFile },
        { "SetTweenFile",						LuaWindow_SetTweenFile },

        //			{ "__newindex",							LuaWindow_NewIndex },
        { "__eq",								LuaWindow_Equal },

        { NULL,									NULL },
    };

    static luaL_reg const s_aWndEditMetaTable[] =
    {
        { "SetPadding",							LuaEdit_SetPadding },
        { "GetPadding",							LuaEdit_GetPadding },
        { "SetText",							LuaEdit_SetText },
        { "GetText",							LuaEdit_GetText },
        { "GetTextLength",						LuaEdit_GetTextLength },
        { "GetImageCount",						LuaEdit_GetImageCount },
        { "ClearText",							LuaEdit_ClearText },
        { "InsertObj",							LuaEdit_InsertObj },
        { "GetTextStruct",                      LuaEdit_GetTextStruct },
        { "SetType",							LuaEdit_SetType },
        { "SetLimit",							LuaEdit_SetLimit },
        { "GetLimit",							LuaEdit_GetLimit },
        { "SetLimitMultiByte",					LuaEdit_SetLimitMultiByte },
        { "IsLimitMultiByte",					LuaEdit_IsLimitMultiByte },
        { "SelectAll",							LuaEdit_SelectAll },
        { "CancelSelect",						LuaEdit_CancelSelect },
        { "SetFontScheme",						LuaEdit_SetFontScheme },
        { "GetFontScheme",						LuaEdit_GetFontScheme },
        { "SetFontColor",						LuaEdit_SetFontColor },
        { "InsertText",							LuaEdit_InsertText },
        { "Backspace",							LuaEdit_Backspace },
        { "SetMultiLine",						LuaEdit_SetMultiLine },
        { "IsMultiLine",						LuaEdit_IsMultiLine },
        { "SetFontSpacing",						LuaEdit_SetFontSpacing },
        { "SetRowSpacing",						LuaEdit_SetRowSpacing },
        { "SetFocusBgColor",					LuaEdit_SetFocusBgColor },
        { "SetSelectBgColor",					LuaEdit_SetSelectBgColor },
        { "SetSelectFontScheme",				LuaEdit_SetSelectFontScheme },
        { "SetCurSel",							LuaEdit_SetCurSel },
        { "SetCaretPos",					    LuaEdit_SetCaretPos },
        { "GetCaretPos",					    LuaEdit_GetCaretPos },
        { "SetPlaceholderRelX",					LuaEdit_SetPlaceholderRelX },
        { "GetPlaceholderRelX",					LuaEdit_GetPlaceholderRelX },
        { "SetPlaceholderRelY",					LuaEdit_SetPlaceholderRelY },
        { "GetPlaceholderRelY",					LuaEdit_GetPlaceholderRelY },
        { "SetPlaceholderText",					LuaEdit_SetPlaceholderText },
        { "GetPlaceholderText",					LuaEdit_GetPlaceholderText },
        { "SetPlaceholderFontScheme",			LuaEdit_SetPlaceholderFontScheme },
        { "GetPlaceholderFontScheme",			LuaEdit_GetPlaceholderFontScheme },
        { "SetPlaceholderFontColor",			LuaEdit_SetPlaceholderFontColor },
        { "GetPlaceholderFontColor",			LuaEdit_GetPlaceholderFontColor },
        { "SetPlaceholderVAlign",      		    LuaEdit_SetPlaceholderVAlign },
        { "GetPlaceholderVAlign",     		    LuaEdit_GetPlaceholderVAlign },
        { "SetPlaceholderHAlign",      		    LuaEdit_SetPlaceholderHAlign },
        { "GetPlaceholderHAlign",     		    LuaEdit_GetPlaceholderHAlign },
        { "SetPlaceholderAlpha",      		    LuaEdit_SetPlaceholderAlpha },
        { "GetPlaceholderAlpha",     		    LuaEdit_GetPlaceholderAlpha },
        { "SetStatus",							LuaEdit_SetStatus },
        { "IsStatus",							LuaEdit_IsStatus },

        { NULL,									NULL },
    };

    static luaL_reg const s_aWndButtonMetaTable[] =
    {
        //------------WndButton----------------------
        { "IsEnabled",							LuaButton_IsEnabled },
        { "Enable",								LuaButton_Enable },
        { "SetAnimateGroupNormal",				LuaButton_SetAnimateGroupNormal },
        { "SetAnimateGroupMouseOver",			LuaButton_SetAnimateGroupMouseOver },
        { "SetAnimateGroupMouseDown",			LuaButton_SetAnimateGroupMouseDown },
        { "SetAnimateGroupDisable",				LuaButton_SetAnimateGroupDisable },
        { "RegisterLButtonDrag",			    LuaButton_RegisterLButtonDrag },
        { "UnregisterLButtonDrag",			    LuaButton_UnregisterLButtonDrag },
        { "IsLButtonDragable",				    LuaButton_IsLButtonDragable },
        { "RegisterRButtonDrag",			    LuaButton_RegisterRButtonDrag },
        { "UnregisterRButtonDrag",			    LuaButton_UnregisterRButtonDrag },
        { "IsRButtonDragable",				    LuaButton_IsRButtonDragable },
        { "SetStatus",							LuaButton_SetStatus },
        { "IsStatus",							LuaButton_IsStatus },

        { NULL,									NULL },
    };

    static luaL_reg const s_aWndCheckBoxMetaTable[] =
    {
        //------------WndCheckBox----------------------
        { "IsCheckBoxActive",					LuaCheckBox_IsCheckBoxActive },
        { "Enable",								LuaCheckBox_Enable },
        { "IsEnabled",							LuaCheckBox_IsEnabled },
        { "IsCheckBoxChecked",					LuaCheckBox_IsCheckBoxChecked },
        { "Check",								LuaCheckBox_Check },
        { "ToggleCheck",						LuaCheckBox_ToggleCheck },
        { "SetAnimation",						LuaCheckBox_SetAnimation },
        { "SetStatus",							LuaCheckBox_SetStatus },
        { "IsStatus",							LuaCheckBox_IsStatus },

        { NULL,									NULL },
    };

    static luaL_reg const s_aWndNewScrollBarMetaTable[] =
    {
        { "Enable",                             LuaNewScrollBar_Enable },
        { "SetScrollPos",						LuaNewScrollBar_SetScrollPos },
        { "GetScrollPos",						LuaNewScrollBar_GetScrollPos },
        { "SetStepCount",						LuaNewScrollBar_SetStepCount },
        { "GetStepCount",						LuaNewScrollBar_GetStepCount },
        { "SetPageStepCount",					LuaNewScrollBar_SetPageStepCount },
        { "GetPageStepCount",					LuaNewScrollBar_GetPageStepCount },
        { "ScrollPrev",							LuaNewScrollBar_ScrollPrev },
        { "ScrollNext",							LuaNewScrollBar_ScrollNext },
        { "ScrollPagePrev",						LuaNewScrollBar_ScrollPagePrev },
        { "ScrollPageNext",						LuaNewScrollBar_ScrollPageNext },
        { "ScrollHome",							LuaNewScrollBar_ScrollHome },
        { "ScrollEnd",							LuaNewScrollBar_ScrollEnd },
        { "SetDragStep",						LuaNewScrollBar_SetDragStep},
        { "EnableFreeOpt",						LuaNewScrollBar_EnableFreeOpt},

        { NULL,									NULL },
    };

    static luaL_reg const s_aWndScrollMetaTable[] =
    {
        { "SetScrollVerStepSize",			    LuaScroll_SetScrollVerStepSize },
        { "SetScrollHorStepSize",			    LuaScroll_SetScrollHorStepSize },
        { NULL,									NULL },
    };

    static luaL_reg const s_aWndSceneMetaTable[] =
    {
        { "SetScene",							LuaScene_SetScene },
        { "EnableRenderTerrain",				LuaScene_EnableRenderTerrain },
        { "EnableRenderSkyBox",					LuaScene_EnableRenderSkyBox },
        { "EnableFrameMove",					LuaScene_EnableFrameMove },

        { NULL,									NULL },
    };

    static luaL_reg const s_aWndMovieMetaTable[] =
    {
        { "Play",								LuaMovie_Play },
        { "Stop",								LuaMovie_Stop },
        { "SetVolume",							LuaMovie_SetVolume },
        { "IsFinished",							LuaMovie_IsFinished },
        { "SetLoop",							LuaMovie_SetLoop },
        { "GetMovieSize",						LuaMovie_GetMovieSize },

        { NULL,									NULL },
    };

    static luaL_reg const s_aWndTextureMetaTable[] =
    {
        { "SetTexture",							LuaTexture_SetTexture },

        { NULL,									NULL },
    };

    static luaL_reg const s_aWndPageSetMetaTable[] =
    {
        { "ActivePage",							LuaPageSet_ActivePage },
        { "GetActivePageIndex",					LuaPageSet_GetActivePageIndex },
        { "GetLastActivePageIndex",				LuaPageSet_GetLastActivePageIndex },
        { "AddPage",							LuaPageSet_AddPage },
        { "GetActivePage",						LuaPageSet_GetActivePage },
        { "GetActiveCheckBox",					LuaPageSet_GetActiveCheckBox },

        { NULL,									NULL },
    };

    static luaL_reg const s_aWndFrameMetaTable[] =
    {
        { "EnableDrag",							LuaFrame_EnableDrag },
        { "IsDragable",							LuaFrame_IsDragable },
        { "EnableFollowMouse",					LuaFrame_EnableFollowMouse },
        { "IsFollowMouseMove",					LuaFrame_IsFollowMouseMove },
        { "SetDragArea",						LuaFrame_SetDragArea },
        { "RegisterEvent",						LuaFrame_RegisterEvent },
        { "UnRegisterEvent",					LuaFrame_UnRegisterEvent },
        { "FocusPrev",							LuaFrame_FocusPrev },
        { "FocusNext",							LuaFrame_FocusNext },
        { "FocusHome",							LuaFrame_FocusHome },
        { "FocusEnd",							LuaFrame_FocusEnd },
        { "FadeIn",								LuaFrame_FadeIn },
        { "FadeOut",							LuaFrame_FadeOut },
        { "ShowWhenUIHide",						LuaFrame_ShowWhenUIHide },
        { "HideWhenUIHide",						LuaFrame_HideWhenUIHide },
        { "IsVisibleWhenUIHide",				LuaFrame_IsVisibleWhenUIHide },
        { "IsAddOn",				            LuaFrame_IsAddOn },
        { "CreateItemData",				        LuaFrame_CreateItemData },
        { "RemoveItemData",				        LuaFrame_RemoveItemData },
        { "LookUpItemData",				        LuaFrame_LookUpItemData },
        { "GetItemDataKey",				        LuaFrame_GetItemDataKey },

        { NULL,									NULL },
    };

    static luaL_reg const s_aWndMinimapMetaTable[] =
    {
        { "SetMapPath",							LuaMinimap_SetMapPath },
        { "SetScale",							LuaMinimap_SetScale },
        { "GetScale",							LuaMinimap_GetScale },
        { "UpdataStaticPoint",					LuaMinimap_UpdateStaticPoint },
        { "UpdataAnimatePoint",					LuaMinimap_UpdateAnimatePoint },
        { "UpdataArrowPoint",					LuaMinimap_UpdateArrowPoint },
        { "UpdateRegion",						LuaMinimap_UpdateRegion },
        { "RemovePoint",						LuaMinimap_RemovePoint },
        { "UpdataSelfPos",						LuaMinimap_UpdateSelfPos },
        { "Clear",								LuaMinimap_Clear },
        { "GetOverObj",							LuaMinimap_GetOverObj },
        { "GetSendPos",							LuaMinimap_GetSendPos },

        { NULL,									NULL },
    };

    static luaL_reg const s_aWndWebPageMetaTable[] =
    {
        { "Navigate",							LuaWebPage_Navigate },
        { "NavigateBindCard",					LuaWebPage_NavigateBindCard },
        { "CanGoBack",							LuaWebPage_CanGoBack },
        { "CanGoForward",						LuaWebPage_CanGoForward },
        { "GoBack",								LuaWebPage_GoBack },
        { "GoForward",							LuaWebPage_GoForward },
        { "Refresh",							LuaWebPage_Refresh },
        { "GetLocationName",					LuaWebPage_GetLocationName },
        { "GetLocationURL",						LuaWebPage_GetLocationURL },
        { "GetDocument",						LuaWebPage_GetDocument },
        { "EnableUpdate",						LuaWebPage_EnableUpdate },

        { NULL,									NULL },
    };

    static luaL_reg const s_aWndSfxMetaTable[] =
    {
        { "LoadSFX",							LuaWndSFX_LoadSFX },
        { "Play",							    LuaWndSFX_Play },
        { "Scale",						        LuaWndSFX_SetModelScale },
        { "SetModelScale",						LuaWndSFX_SetModelScale },
        { "GetModelScale",						LuaWndSFX_GetModelScale },
        { "Get3DModel",							LuaWndSFX_Get3DModel},
        { "Set2DRotation",						LuaWndSFX_Set2DRotation},

        { NULL,									NULL },
    };

    static luaL_reg const s_aWndContainerMetaTable[] =
    {
        { "SetContainerType",			        LuaContainer_SetContainerType },
        { "FormatAllContentPos",			    LuaContainer_FormatAllContentPos },
        { "GetAllContentSize",			        LuaContainer_GetAllContentSize },
        { "AppendContentFromIni",			    LuaContainer_AppendContentFromIni },
        { "Clear",              			    LuaContainer_Clear },
        { "GetAllContentCount",                 LuaContainer_GetAllContentCount },
        { "SetColumn",              			LuaContainer_SetColumn },
        { "SetDrawStyle",              			LuaContainer_SetDrawStyle },
        { "LookupContent",              		LuaContainer_LookupContent },
        { "SetStartRelPos",              		LuaContainer_SetStartRelPos },
        { "GetStartRelPos",              		LuaContainer_GetStartRelPos },
        { "SetVAlign",               		    LuaContainer_SetVAlign },
        { "GetVAlign",              		    LuaContainer_GetVAlign },
        { "SetHAlign",               		    LuaContainer_SetHAlign },
        { "GetHAlign",              		    LuaContainer_GetHAlign },
        { "LoadShapTexture",					LuaContainer_LoadShapTexture },
        { "UnloadShapTexture",					LuaContainer_UnloadShapTexture },

        { NULL,									NULL },
    };

    int bEnableHook = false;
#ifndef KG_PUBLISH
    bEnableHook = g_pUI->m_Config.m_bEnableRecord;
#endif
    KScriptLoader::RegisterLibTable(L, "Cursor",	s_aCursorLibTable);
    KScriptLoader::RegisterLibTable(L, "Wnd",		s_aWndLibTable);
    KScriptLoader::RegisterLibTable(L, "Station",	s_aStationLibTable);

    KScriptLoader::RegisterMetaTable(L, "WndWindow",		s_aWndWindowMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndEdit",			s_aWndWindowMetaTable, s_aWndEditMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndButton",		s_aWndWindowMetaTable, s_aWndButtonMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndCheckBox",		s_aWndWindowMetaTable, s_aWndCheckBoxMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndNewScrollBar",	s_aWndWindowMetaTable, s_aWndNewScrollBarMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndScroll",		s_aWndWindowMetaTable, s_aWndScrollMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndScene",			s_aWndWindowMetaTable, s_aWndSceneMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndMovie",			s_aWndWindowMetaTable, s_aWndMovieMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndTexture",		s_aWndWindowMetaTable, s_aWndTextureMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndPageSet",		s_aWndWindowMetaTable, s_aWndPageSetMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndPage",			s_aWndWindowMetaTable, s_aWndWindowMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndFrame",			s_aWndWindowMetaTable, s_aWndFrameMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndMinimap",		s_aWndWindowMetaTable, s_aWndMinimapMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndWebPage",		s_aWndWindowMetaTable, s_aWndWebPageMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndSFX",			s_aWndWindowMetaTable, s_aWndSfxMetaTable, bEnableHook);
    KScriptLoader::RegisterMetaTable(L, "WndContainer",		s_aWndWindowMetaTable,s_aWndContainerMetaTable, bEnableHook);
}
