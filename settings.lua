local config = require("config")


data:extend{
    {
        type = "int-setting",
        name = config.REFRESH_RATE_NAME,
        setting_type = "runtime-global",
        default_value = config.REFRESH_RATE,
        minimum_value = 1,
    }
}