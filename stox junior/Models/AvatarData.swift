import SwiftUI

enum AvatarCategory: String, CaseIterable, Codable {
    case animals    = "Animal Pals"
    case myths = "Legends"
    case popCulture   = "Heroes"

    var gemCost: Int {
        switch self {
        case .animals:    return 30
        case .myths: return 100
        case .popCulture:   return 500
        }
    }

    var sfIcon: String {
        switch self {
        case .animals:    return "pawprint.fill"
        case .myths: return "film.fill"
        case .popCulture:   return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .animals:    return Color(red: 0.20, green: 0.68, blue: 0.35)
        case .myths: return Color(red: 0.25, green: 0.50, blue: 0.95)
        case .popCulture:   return Color(red: 0.58, green: 0.18, blue: 0.92)
        }
    }

    // DiceBear style used for this tier
    var diceBearStyle: String {
        switch self {
        case .animals:    return "fun-emoji"   // colorful expressive faces
        case .myths: return "pixel-art"   // retro pixel characters
        case .popCulture:   return "adventurer"  // illustrated fantasy characters
        }
    }
}

struct AvatarItem: Identifiable, Equatable {
    let id: String
    let name: String
    let category: AvatarCategory
    let seed: String    // DiceBear seed — determines the character design
    let bgColor: String // Hex without #, unique per avatar

    var url: URL? {
        URL(string: "https://api.dicebear.com/9.x/\(category.diceBearStyle)/png?seed=\(seed)&backgroundColor=\(bgColor)&size=128")
    }
}

extension AvatarItem {
    static let all: [AvatarItem] = animals + popCulture + myths

    // fun-emoji style — each gets its own vivid background
    static let animals: [AvatarItem] = [
        .init(id: "dog",     name: "Tired",     category: .animals, seed: "happydog",    bgColor: "f4845f"),
        .init(id: "cat",     name: "Kiss",     category: .animals, seed: "coolcat",     bgColor: "c77dff"),
        .init(id: "fox",     name: "Scream",     category: .animals, seed: "cleverFox",   bgColor: "f9c74f"),
        .init(id: "bear",    name: "Alien Kiss",    category: .animals, seed: "grizzlyBear", bgColor: "43aa8b"),
        .init(id: "panda",   name: "Tongue",   category: .animals, seed: "pandaRoll",   bgColor: "90e0ef"),
        .init(id: "lion",    name: "Hot",    category: .animals, seed: "lionKing",    bgColor: "f8961e"),
        .init(id: "tiger",   name: "Grr",   category: .animals, seed: "tigerStrike", bgColor: "f72585"),
        .init(id: "koala",   name: "Huh",   category: .animals, seed: "koalaHug",    bgColor: "b5c0da"),
        .init(id: "owl",     name: "Calm",     category: .animals, seed: "wiseOwl",     bgColor: "457b9d"),
        .init(id: "wolf",    name: "Winky",    category: .animals, seed: "moonWolf",    bgColor: "6d6875"),
        .init(id: "eagle",   name: "Smile",   category: .animals, seed: "soaringEagle",bgColor: "2d6a4f"),
        .init(id: "dolphin", name: "Sleepy", category: .animals, seed: "waveDolphin", bgColor: "48cae4"),
    ]

    // pixel-art style — bold hero colors
    static let myths: [AvatarItem] = [
        .init(id: "dragon",   name: "Dragon Whisperer",   category: .popCulture, seed: "fireDragon",  bgColor: "9d0208"),
        .init(id: "unicorn",  name: "Unicorn Queen",  category: .popCulture, seed: "rainbowHorn", bgColor: "e040fb"),
        .init(id: "phoenix",  name: "Phoenix Shifter",  category: .popCulture, seed: "risingFlame", bgColor: "f4511e"),
        .init(id: "mermaid",  name: "Mermaid",  category: .popCulture, seed: "deepSea",     bgColor: "2ec4b6"),
        .init(id: "fairy",    name: "Fairy Messenger",    category: .popCulture, seed: "glowWings",   bgColor: "db2777"),
        .init(id: "vampire",  name: "Vampire Hunter",  category: .popCulture, seed: "midnightBite",bgColor: "6a0572"),
        .init(id: "warrior",  name: "Tree Warrior",  category: .popCulture, seed: "ancientBlade",bgColor: "4a4e69"),
        .init(id: "poseidon", name: "Mad Scientist", category: .popCulture, seed: "tridentWave", bgColor: "023e8a"),
        .init(id: "sorcerer", name: "Sorcerer of Mischeif", category: .popCulture, seed: "arcaneSpell", bgColor: "5c0099"),
        .init(id: "goddess",  name: "Demigoddess",  category: .popCulture, seed: "divineLight", bgColor: "e9b44c"),
        .init(id: "titan",    name: "Titan Slayer",    category: .popCulture, seed: "stoneTitan",  bgColor: "495057"),
        .init(id: "kraken",   name: "Nocturnal Ghost",   category: .popCulture, seed: "deepAbyss",   bgColor: "03045e"),
    ]

    // adventurer style — deep mystical colors
    static let popCulture: [AvatarItem] = [
        .init(id: "ironman",  name: "Green Witch",    category: .myths, seed: "ironManSuit",   bgColor: "e63946"),
        .init(id: "thor",     name: "Curly Girl",        category: .myths, seed: "thorHammer",    bgColor: "4361ee"),
        .init(id: "cap",      name: "Punk Kid",    category: .myths, seed: "shieldCarry",   bgColor: "3a86ff"),
        .init(id: "spidey",   name: "Ginger Girl",  category: .myths, seed: "webSlinger",    bgColor: "c1121f"),
        .init(id: "batman",   name: "Old Man Jones",      category: .myths, seed: "darkKnight",    bgColor: "264653"),
        .init(id: "hp",       name: "Purple Clique",category: .myths, seed: "expelliarmus",  bgColor: "7b2d8b"),
        .init(id: "wizard",   name: "Chill Guy",     category: .myths, seed: "youShallNotPass",bgColor: "1d3557"),
        .init(id: "thering",  name: "Ponygirl",    category: .myths, seed: "oneRingRule",   bgColor: "9c6644"),
        .init(id: "elf",      name: "Googles George",     category: .myths, seed: "elfArcher",     bgColor: "40916c"),
        .init(id: "jedi",     name: "Geek Supreme",        category: .myths, seed: "forceUser",     bgColor: "00b4d8"),
        .init(id: "rocket",   name: "Sweet Child of Someone",   category: .myths, seed: "galaxyFar",     bgColor: "0077b6"),
        .init(id: "sherlock", name: "Mushroom Head",    category: .myths, seed: "221bBaker",     bgColor: "606c38"),
    ]
}
