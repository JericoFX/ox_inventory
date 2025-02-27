Config = {}

-- Server-side configuration
Config.BulkStashSave = true
Config.LogLevel = 1
Config.RandomPrices = false
Config.RandomLoot = true
Config.EvidenceGrade = 2
Config.TrimPlate = true
Config.VehicleLoot = {
    {"sprunk", 1, 1},
    {"water", 1, 1},
    {"garbage", 1, 2, 50},
    {"panties", 1, 1, 5},
    {"money", 1, 50},
    {"money", 200, 400, 5},
    {"bandage", 1, 1}
}
Config.DumpsterLoot = {
    {"mustard", 1, 1},
    {"garbage", 1, 3},
    {"money", 1, 10},
    {"burger", 1, 1}
}
Config.Accounts = {"money"}

return Config