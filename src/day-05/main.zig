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
        return source >= self.sourceStart or source <= self.sourceEnd;
    }

    pub fn getDestination(self: MapKey, source: u64) ?u64 {
        if (!self.containsSource(source)) {
            return null;
        }

        // Should be zero at the least so skipping bound safe std.math.sub
        var difference = source - self.sourceStart;
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

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const inputFile = "src/day-05/input.txt";
    const file = try std.fs.cwd().openFile(inputFile, .{});
    defer file.close();

    var list = ArrayList(u32).init(allocator);
    defer list.deinit();

    var bufReader = std.io.bufferedReader(file.reader());
    var reader = bufReader.reader();
    // Might need to fiddle with this for this input
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

    var total = sumList(u32, list);
    std.debug.print("Total: {d}\n", .{total});
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
