PfExtend_Config["About"]={}
PfExtend_Config_Index["About"]={"Author","Version","Github"}
PfExtend_Config_Template["About"]={
    ["Author"]=function ()
        return {text="Cliencer(海蓝钢板)"}
    end,
    -- Read from the toc so the version lives in exactly one place. It used to
    -- be hardcoded here and drifted from the toc on every release.
    ["Version"]=function ()
        return {text=GetAddOnMetadata("pfExtend", "Version") or "unknown"}
    end,
    ["Github"]=function ()
        return {text="https://github.com/Cliencer/pfExtend"}
    end,

}



