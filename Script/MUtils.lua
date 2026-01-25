local divlib = require('divlib')
local Logger = require('Logger')

local MUtils = {}
MUtils.divlib = divlib

-- Initialize Logger
MUtils.InitLogger = Logger.Init
MUtils.RegisterModule = Logger.RegisterModule

-- Expose Log Functions
MUtils.Log = Logger.Log
MUtils.Warning = Logger.Warning
MUtils.Warnning = Logger.Warnning -- Typo support
MUtils.Error = Logger.Error
MUtils.Debug = Logger.Debug

return MUtils