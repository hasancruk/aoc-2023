const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;

const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const test_allocator = std.testing.allocator;

const utils = @import("utilities");
const sumList = utils.sumList;

const MapKey = struct {
    sourceStart: u64,
    sourceEnd: u64,
    destinationStart: u64,
    destinationEnd: u64,

    pub fn init(sourceStart: u64, destinationStart: u64, range: u64) MapKey {
        return .{
            .sourceStart = sourceStart,
            .destinationStart = destinationStart,
            .sourceEnd = sourceStart + (std.math.sub(u64, range, 1) catch 0),
            .destinationEnd = destinationStart + (std.math.sub(u64, range, 1) catch 0),
        };
    }

    pub fn containsSource(self: MapKey, source: u64) bool {
        return source >= self.sourceStart and source <= self.sourceEnd;
    }

    pub fn getDestination(self: MapKey, source: u64) ?u64 {
        if (!self.containsSource(source)) {
            return null;
        }

        var difference = std.math.sub(u64, source, self.sourceStart) catch 0;
        var result = self.destinationStart + difference;
        return result;
    }
};

const ExtractOptions = struct {
    seeds: *ArrayList(u64),
    seedToSoilMap: *ArrayList(MapKey),
    soilToFertilizerMap: *ArrayList(MapKey),
    fertilizerToWaterMap: *ArrayList(MapKey),
    waterToLightMap: *ArrayList(MapKey),
    lightToTemperatureMap: *ArrayList(MapKey),
    temperatureToHumidityMap: *ArrayList(MapKey),
    humidityToLocationMap: *ArrayList(MapKey),
    currentMap: Map,
};

const Map = enum(u8) {
    seeds,
    seed_to_soil,
    soil_to_fertilizer,
    fertilizer_to_water,
    water_to_light,
    light_to_temperature,
    temperature_to_humidity,
    humidity_to_location,
};

const MapExtractionError = error{
    InvalidMapType,
    MapIndexOutOfBounds,
    InvalidSeedRange,
};

const mapStrings = [_][]const u8{
    "seeds:",
    "seed-to-soil",
    "soil-to-fertilizer",
    "fertilizer-to-water",
    "water-to-light",
    "light-to-temperature",
    "temperature-to-humidity",
    "humidity-to-location",
};

fn extractMapType(line: []const u8) !Map {
    var result: ?Map = null;
    for (mapStrings, 0..) |name, i| {
        if (std.mem.startsWith(u8, line, name)) {
            result = @as(Map, @enumFromInt(i));
        }
    }
    return result orelse MapExtractionError.InvalidMapType;
}

fn extractSeeds(line: []const u8, list: *ArrayList(u64)) !void {
    var iter = std.mem.splitScalar(u8, line, ':');
    _ = iter.next();
    var seeds = std.mem.trim(u8, iter.next().?, " ");
    var seedsIter = std.mem.splitScalar(u8, seeds, ' ');
    while (seedsIter.next()) |seed| {
        try list.append(try std.fmt.parseUnsigned(u64, seed, 10));
    }
}

fn extractMapKey(line: []const u8, list: *ArrayList(MapKey)) !void {
    var iter = std.mem.splitScalar(u8, line, ' ');
    var destinationStart = try std.fmt.parseUnsigned(u64, iter.next().?, 10);
    var sourceStart = try std.fmt.parseUnsigned(u64, iter.next().?, 10);
    var range = try std.fmt.parseUnsigned(u64, iter.next().?, 10);

    var mapKey = MapKey.init(sourceStart, destinationStart, range);

    try list.append(mapKey);
}

fn extractDataToMaps(line: []const u8, options: ExtractOptions) !void {
    switch (options.currentMap) {
        .seeds => try extractSeeds(line, options.seeds),
        .seed_to_soil => try extractMapKey(line, options.seedToSoilMap),
        .soil_to_fertilizer => try extractMapKey(line, options.soilToFertilizerMap),
        .fertilizer_to_water => try extractMapKey(line, options.fertilizerToWaterMap),
        .water_to_light => try extractMapKey(line, options.waterToLightMap),
        .light_to_temperature => try extractMapKey(line, options.lightToTemperatureMap),
        .temperature_to_humidity => try extractMapKey(line, options.temperatureToHumidityMap),
        .humidity_to_location => try extractMapKey(line, options.humidityToLocationMap),
    }
}

const SearchOptions = struct {
    seed: u64,
    seedToSoilMap: []const MapKey,
    soilToFertilizerMap: []const MapKey,
    fertilizerToWaterMap: []const MapKey,
    waterToLightMap: []const MapKey,
    lightToTemperatureMap: []const MapKey,
    temperatureToHumidityMap: []const MapKey,
    humidityToLocationMap: []const MapKey,
    results: *ArrayList(u64),
};

fn searchAlmanac(options: SearchOptions) !void {
    var location: u64 = options.seed;

    for (options.seedToSoilMap) |mapKey| {
        var maybeMatch = mapKey.getDestination(options.seed);
        if (maybeMatch) |match| {
            location = match;
            break;
        }
    }

    for (options.soilToFertilizerMap) |mapKey| {
        var maybeMatch = mapKey.getDestination(location);
        if (maybeMatch) |match| {
            location = match;
            break;
        }
    }

    for (options.fertilizerToWaterMap) |mapKey| {
        var maybeMatch = mapKey.getDestination(location);
        if (maybeMatch) |match| {
            location = match;
            break;
        }
    }

    for (options.waterToLightMap) |mapKey| {
        var maybeMatch = mapKey.getDestination(location);
        if (maybeMatch) |match| {
            location = match;
            break;
        }
    }

    for (options.lightToTemperatureMap) |mapKey| {
        var maybeMatch = mapKey.getDestination(location);
        if (maybeMatch) |match| {
            location = match;
            break;
        }
    }

    for (options.temperatureToHumidityMap) |mapKey| {
        var maybeMatch = mapKey.getDestination(location);
        if (maybeMatch) |match| {
            location = match;
            break;
        }
    }

    for (options.humidityToLocationMap) |mapKey| {
        var maybeMatch = mapKey.getDestination(location);
        if (maybeMatch) |match| {
            location = match;
            break;
        }
    }

    try options.results.append(location);
}

fn toLongSeedList(seeds: []const u64, longSeeds: *ArrayList(u64)) !void {
    if (@mod(seeds.len, 2) != 0) {
        return MapExtractionError.InvalidSeedRange;
    }

    var start: ?u64 = null;
    var range: ?u64 = null;

    for (seeds, 0..) |seed, i| {
        if (@mod(i, 2) == 0) {
            start = seed;
        } else {
            range = seed;
        }

        if (range) |rangeUpper| {
            for (0..rangeUpper) |r| {
                try longSeeds.append(start.? + r);
            }
            start = null;
            range = null;
        }
    }
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const inputFile = "src/day-05/input.txt";
    const file = try std.fs.cwd().openFile(inputFile, .{});
    defer file.close();

    var list = ArrayList(u64).init(allocator);
    defer list.deinit();

    var bufReader = std.io.bufferedReader(file.reader());
    var reader = bufReader.reader();
    var buffer: [512]u8 = undefined;

    var seeds = ArrayList(u64).init(allocator);
    defer seeds.deinit();
    var seedToSoilMap = ArrayList(MapKey).init(allocator);
    defer seedToSoilMap.deinit();
    var soilToFertilizerMap = ArrayList(MapKey).init(allocator);
    defer soilToFertilizerMap.deinit();
    var fertilizerToWaterMap = ArrayList(MapKey).init(allocator);
    defer fertilizerToWaterMap.deinit();
    var waterToLightMap = ArrayList(MapKey).init(allocator);
    defer waterToLightMap.deinit();
    var lightToTemperatureMap = ArrayList(MapKey).init(allocator);
    defer lightToTemperatureMap.deinit();
    var temperatureToHumidityMap = ArrayList(MapKey).init(allocator);
    defer temperatureToHumidityMap.deinit();
    var humidityToLocationMap = ArrayList(MapKey).init(allocator);
    defer humidityToLocationMap.deinit();

    var currentMap: Map = undefined;
    var lineIndex: u32 = 0;
    var checkMapType = true;

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (lineIndex == 0) {
            currentMap = .seeds;
            checkMapType = false;
        }

        if (checkMapType) {
            currentMap = try extractMapType(line);
            checkMapType = false;
            continue;
        }

        if (std.mem.eql(u8, line, "")) {
            checkMapType = true;
            continue;
        }

        try extractDataToMaps(line, .{
            .seeds = &seeds,
            .seedToSoilMap = &seedToSoilMap,
            .soilToFertilizerMap = &soilToFertilizerMap,
            .fertilizerToWaterMap = &fertilizerToWaterMap,
            .waterToLightMap = &waterToLightMap,
            .lightToTemperatureMap = &lightToTemperatureMap,
            .temperatureToHumidityMap = &temperatureToHumidityMap,
            .humidityToLocationMap = &humidityToLocationMap,
            .currentMap = currentMap,
        });

        lineIndex += 1;
    }

    var longSeeds = ArrayList(u64).init(allocator);
    defer longSeeds.deinit();

    try toLongSeedList(seeds.items, &longSeeds);

    for (longSeeds.items) |seed| {
        try searchAlmanac(.{
            .seed = seed,
            .seedToSoilMap = seedToSoilMap.items,
            .soilToFertilizerMap = soilToFertilizerMap.items,
            .fertilizerToWaterMap = fertilizerToWaterMap.items,
            .waterToLightMap = waterToLightMap.items,
            .lightToTemperatureMap = lightToTemperatureMap.items,
            .temperatureToHumidityMap = temperatureToHumidityMap.items,
            .humidityToLocationMap = humidityToLocationMap.items,
            .results = &list,
        });
    }

    var lowest = std.mem.min(u64, list.items);
    std.debug.print("Lowest: {d}\n", .{lowest});
}

test "day 05" {
    var seeds = ArrayList(u64).init(test_allocator);
    defer seeds.deinit();
    var seedToSoilMap = ArrayList(MapKey).init(test_allocator);
    defer seedToSoilMap.deinit();
    var soilToFertilizerMap = ArrayList(MapKey).init(test_allocator);
    defer soilToFertilizerMap.deinit();
    var fertilizerToWaterMap = ArrayList(MapKey).init(test_allocator);
    defer fertilizerToWaterMap.deinit();
    var waterToLightMap = ArrayList(MapKey).init(test_allocator);
    defer waterToLightMap.deinit();
    var lightToTemperatureMap = ArrayList(MapKey).init(test_allocator);
    defer lightToTemperatureMap.deinit();
    var temperatureToHumidityMap = ArrayList(MapKey).init(test_allocator);
    defer temperatureToHumidityMap.deinit();
    var humidityToLocationMap = ArrayList(MapKey).init(test_allocator);
    defer humidityToLocationMap.deinit();

    var lines =
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ;
    _ = lines;
}
