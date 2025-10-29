-- Perusahaan Sorchesus - Skrip GUI Sisi Klien Lengkap
-- Perbaikan pembaruan Crucible dan penambahan anomali Yin, Yang, dan ERROR
-- Dimodifikasi untuk ramah seluler
-- Diperbarui dengan anomali baru, penjaga luar, penurunan mood, dan interval pekerja yang disesuaikan
-- Perbaikan kesalahan: nil.HP dan sub pada nil
-- Penambahan tombol Eksekusi dan tombol Protokol Terminator
-- Mengubah mood awal Apocalypse Herald menjadi 45
-- Memperbarui Protokol Terminator untuk memanggil agen sementara yang menyerang dengan prioritas dan menahan anomali
-- Penambahan anomali Blooming Blood Tree dan Prince of Fame
-- Penambahan perilaku anomali tidak bernyawa: bunuh pekerja pada mood 0 alih-alih melanggar
-- Memodifikasi Protokol Terminator untuk menahan alih-alih membunuh permanen
-- Penambahan gulir horizontal ke bilah atas
-- Penambahan paywall untuk info anomali
-- Penambahan hadiah senjata anomali (senjata dan armor MX)
-- Penambahan hari, kuota, tombol akhiri hari, tombol reroll, penghitung hari, layar akhiri hari, penghitung kuota
-- Penambahan penyerang
-- Perbaikan kesalahan yang mencegah animasi serangan dengan mengisi semua basis data serangan sphere dengan kesulitan yang diskalakan

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local isMobile = UserInputService.TouchEnabled

-- Kuota
local Quotas = {750, 1000, 2500, 5000, 9000, 17500, 30000, 55555, 83000, 100000}

-- Data Serangan Dasar
local BaseRaids = {
    {
        name = "Hijau",
        quote = "Mereka lapar akan apa yang telah hilang",
        lostQuote = "Bergabunglah dengan Kami",
        color = Color3.fromRGB(0, 255, 0),
        anomalies = {
            {name = "Zombie Lemah", count = 10, hp = 250, dmg = 35},
            {name = "Zombie Normal", count = 3, hp = 750, dmg = 75}
        }
    },
    {
        name = "Ungu",
        quote = "Ritual baru saja dimulai",
        lostQuote = "Mantra telah dilemparkan",
        color = Color3.fromRGB(148, 0, 211),
        anomalies = {
            {name = "Penyihir Hitam", count = 5, hp = 175, dmg = 100},
            {name = "Penguntit Bayangan", count = 10, hp = 245, dmg = 50}
        }
    },
    {
        name = "Merah",
        quote = "Makanan yang Sempurna",
        lostQuote = "Selamat",
        color = Color3.fromRGB(255, 0, 0),
        anomalies = {
            {name = "Cairan Daging", count = 7, hp = 200, dmg = 80},
            {name = "Siput Tersenyum", count = 8, hp = 125, dmg = 75}
        }
    },
    {
        name = "Biru",
        quote = "Air pasang sedang naik",
        lostQuote = "Permukaan memudar",
        color = Color3.fromRGB(0, 0, 255),
        anomalies = {
            {name = "Ikan Koi Giok", count = 5, hp = 175, dmg = 50},
            {name = "Hiu Monster", count = 5, hp = 210, dmg = 80}
        }
    },
    {
        name = "Oranye",
        quote = "Sebuah percikan menyala",
        lostQuote = "Asap naik dari kekalahanmu",
        color = Color3.fromRGB(255, 165, 0),
        anomalies = {
            {name = "Golem Api", count = 7, hp = 150, dmg = 40},
            {name = "Blazer", count = 5, hp = 200, dmg = 65}
        }
    }
}

-- Fungsi untuk menskalakan serangan untuk sphere lebih tinggi
local function ScaleRaids(baseRaids, scaleFactor)
    local scaled = {}
    for _, raid in ipairs(baseRaids) do
        local newRaid = {
            name = raid.name,
            quote = raid.quote,
            lostQuote = raid.lostQuote,
            color = raid.color,
            anomalies = {}
        }
        for _, ano in ipairs(raid.anomalies) do
            table.insert(newRaid.anomalies, {
                name = ano.name,
                count = ano.count,
                hp = math.floor(ano.hp * scaleFactor),
                dmg = math.floor(ano.dmg * scaleFactor)
            })
        }
        table.insert(scaled, newRaid)
    end
    return scaled
end

-- Basis Data Serangan dengan kesulitan yang diskalakan
local RaidDatabase = {
    Troposphere = ScaleRaids(BaseRaids, 1),
    Stratosphere = ScaleRaids(BaseRaids, 2),
    Mesosphere = ScaleRaids(BaseRaids, 4),
    Thermosphere = ScaleRaids(BaseRaids, 8),
    Exosphere = ScaleRaids(BaseRaids, 16)
}

-- Data Game
local GameData = {
    Crucible = 100,
    OwnedAnomalies = {},
    WhiteTrainActive = false,
    TrainTimer = 0,
    CurrentDocuments = {},
    CosmicShardCoreHealth = 15700,
    MaxCoreHealth = 15700,
    BreachedAnomalies = {},
    WorkerNames = {"Michael", "Christina", "Tenna", "Ethan", "Andy", "Joe", "Richard", "Kaleb", "Brian"},
    GuardNames = {"Peter", "Rick", "Kyle", "Jayden", "Nolan", "Steven", "Spencer"},
    OwnedWorkers = {},
    OwnedGuards = {},
    OuterGuards = {},
    TerminatorAgents = {},
    TerminatorActive = false,
    LastGlobalBreachTime = 0,
    OwnedMXWeapons = {},
    OwnedMXArmors = {},
    CurrentDay = 1,
    DailyCrucible = 0,
    AnomaliesAcceptedToday = 0,
    DocumentsPurchasedToday = false,
    TotalBreaches = 0,
    WorkersDied = 0,
    GuardsDied = 0,
    CurrentRaid = nil,
    RaidEntities = {}
}

-- Peta Level Penjaga
local GuardLevels = {
    ["Penjaga Lemah"] = 1,
    ["Penjaga Normal"] = 2,
    ["Penjaga Kuat"] = 3,
    ["Penjaga Tangguh"] = 4,
    ["Penjaga Super"] = 5
}

-- Basis Data Anomali
local AnomalyDatabase = {
    ["Bola Mata Menangis"] = {
        Description = "Air Mata Berdosa, Perbuatan Berdosa.",
        DangerClass = "X",
        BaseMood = 50,
        WorkResults = {
            Knowledge = {Success = 0.6, Crucible = 5, MoodChange = -5},
            Social = {Success = 0.95, Crucible = 45, MoodChange = 15},
            Hunt = {Success = 0.2, Crucible = 1, MoodChange = -20},
            Passive = {Success = 0.8, Crucible = 30, MoodChange = 10}
        },
        BreachChance = 0.005,
        BreachForm = {
            Name = "Tangis Darah",
            Health = 35,
            M1Damage = 5,
            Abilities = {}
        },
        Costs = {Stat = 100, Knowledge = 50, Social = 75, Hunt = 45, Passive = 60, BreachForm = 250, MXWeapon = 350, MXArmor = 450},
        ManagementTips = {},
        MXWeapon = {Name = "Pemancar Mata Darah", Damage = 25, Chance = 0.05, MinLevel = 1, MaxLevel = 5},
        MXArmor = {Name = "Armor Keputusasaan", Health = 100, Chance = 0.02, MinLevel = 1, MaxLevel = 5}
    },
    ["Bayangan Berbisik"] = {
        Description = "Ia tahu rahasiamu, dan ia akan memberitahukannya semua.",
        DangerClass = "XI",
        BaseMood = 40,
        WorkResults = {
            Knowledge = {Success = 0.7, Crucible = 15, MoodChange = 10},
            Social = {Success = 0.4, Crucible = 8, MoodChange = -15},
            Hunt = {Success = 0.3, Crucible = 5, MoodChange = -10},
            Passive = {Success = 0.5, Crucible = 12, MoodChange = 5}
        },
        BreachChance = 0.015,
        BreachForm = {
            Name = "Penguntit Bayangan",
            Health = 80,
            M1Damage = 12,
            Abilities = {"Tidak Terlihat", "Bisikan Kegilaan"}
        },
        Costs = {Stat = 300, Knowledge = 120, Social = 60, Hunt = 80, Passive = 100, BreachForm = 500, MXWeapon = 999, MXArmor = 1200},
        ManagementTips = {},
        MXWeapon = {Name = "Pembisik Rahasia", Damage = 120, Chance = 0.03, MinLevel = 1, MaxLevel = 3},
        MXArmor = {Name = "Selubung Misteri", Health = 600, Chance = 0.015, MinLevel = 1, MaxLevel = 3}
    },
    ["Jantung Mesin Jam"] = {
        Description = "Tik tok, waktumu hampir habis.",
        DangerClass = "XI",
        BaseMood = 60,
        WorkResults = {
            Knowledge = {Success = 0.8, Crucible = 20, MoodChange = 8},
            Social = {Success = 0.6, Crucible = 15, MoodChange = -8},
            Hunt = {Success = 0.5, Crucible = 10, MoodChange = -5},
            Passive = {Success = 0.7, Crucible = 18, MoodChange = 12}
        },
        BreachChance = 0.01,
        BreachForm = {
            Name = "Pembelah Waktu",
            Health = 120,
            M1Damage = 15,
            Abilities = {"Hentikan Waktu", "Serangan Cepat"}
        },
        Costs = {Stat = 275, Knowledge = 145, Social = 120, Hunt = 75, Passive = 80, BreachForm = 510},
        ManagementTips = {}
    },
    ["Peti Mati Tersenyum"] = {
        Description = "Istirahat abadi, istirahat dengan senyuman.",
        DangerClass = "XII",
        BaseMood = 30,
        WorkResults = {
            Knowledge = {Success = 0.5, Crucible = 35, MoodChange = -10},
            Social = {Success = 0.3, Crucible = 20, MoodChange = -25},
            Hunt = {Success = 0.6, Crucible = 40, MoodChange = 5},
            Passive = {Success = 0.4, Crucible = 25, MoodChange = -15}
        },
        BreachChance = 0.025,
        BreachForm = {
            Name = "Kematian Tersenyum",
            Health = 200,
            M1Damage = 25,
            Abilities = {"Sentuhan Kematian", "Aura Ketakutan", "Perangkap Peti Mati"}
        },
        Costs = {Stat = 660, Knowledge = 150, Social = 135, Hunt = 166, Passive = 121, BreachForm = 850},
        ManagementTips = {}
    },
    ["Orkestra Merah Darah"] = {
        Description = "Sebuah simfoni yang ditulis dalam darah dan jeritan.",
        DangerClass = "XII",
        BaseMood = 45,
        WorkResults = {
            Knowledge = {Success = 0.6, Crucible = 30, MoodChange = 5},
            Social = {Success = 0.7, Crucible = 42, MoodChange = 10},
            Hunt = {Success = 0.4, Crucible = 25, MoodChange = -12},
            Passive = {Success = 0.5, Crucible = 28, MoodChange = 8}
        },
        BreachChance = 0.02,
        BreachForm = {
            Name = "Maestro Rasa Sakit",
            Health = 180,
            M1Damage = 20,
            Abilities = {"Gelombang Suara", "Melodi Hipnotis", "Ledakan Crescendo"}
        },
        Costs = {Stat = 650, Knowledge = 175, Social = 190, Hunt = 145, Passive = 160, BreachForm = 900},
        ManagementTips = {}
    },
    ["Pengamat Kekosongan"] = {
        Description = "Tatap ke jurang, dan ia menatap kembali dengan lapar.",
        DangerClass = "XIII",
        BaseMood = 20,
        WorkResults = {
            Knowledge = {Success = 0.4, Crucible = 60, MoodChange = -15},
            Social = {Success = 0.2, Crucible = 35, MoodChange = -30},
            Hunt = {Success = 0.5, Crucible = 55, MoodChange = 10},
            Passive = {Success = 0.3, Crucible = 40, MoodChange = -20}
        },
        BreachChance = 0.04,
        BreachForm = {
            Name = "Avatar Kekosongan",
            Health = 350,
            M1Damage = 35,
            Abilities = {"Tarik Kekosongan", "Robek Realitas", "Penguras Keberadaan", "Ledakan Kegelapan"}
        },
        Costs = {Stat = 980, Knowledge = 260, Social = 210, Hunt = 298, Passive = 250, BreachForm = 5200},
        ManagementTips = {}
    },
    ["Anak Api Abadi"] = {
        Description = "Lahir dari abu, merindukan kehangatan yang tak pernah bisa dirasakannya.",
        DangerClass = "XIII",
        BaseMood = 35,
        WorkResults = {
            Knowledge = {Success = 0.5, Crucible = 50, MoodChange = -8},
            Social = {Success = 0.6, Crucible = 65, MoodChange = 15},
            Hunt = {Success = 0.3, Crucible = 30, MoodChange = -25},
            Passive = {Success = 0.4, Crucible = 45, MoodChange = -10}
        },
        BreachChance = 0.035,
        BreachForm = {
            Name = "Inkarnasi Neraka",
            Health = 280,
            M1Damage = 30,
            Abilities = {"Ledakan Api", "Pembakaran", "Jejak Api", "Kebangkitan Phoenix"}
        },
        Costs = {Stat = 1000, Knowledge = 260, Social = 285, Hunt = 243, Passive = 255, BreachForm = 5500},
        ManagementTips = {}
    },
    ["Pembawa Wahyu Kiamat"] = {
        Description = "Akhir sudah dekat, dan datang dengan senyuman bengkok.",
        DangerClass = "XIV",
        BaseMood = 45,
        WorkResults = {
            Knowledge = {Success = 0.3, Crucible = 100, MoodChange = -20},
            Social = {Success = 0.1, Crucible = 50, MoodChange = -40},
            Hunt = {Success = 0.4, Crucible = 90, MoodChange = 15},
            Passive = {Success = 0.2, Crucible = 60, MoodChange = -30}
        },
        BreachChance = 0.06,
        BreachForm = {
            Name = "Pembawa Akhir Zaman",
            Health = 600,
            M1Damage = 50,
            Abilities = {"Gelombang Kiamat", "Runtuhnya Realitas", "Bunuh Instan", "Panggil Minion", "Pengakhiri Dunia"}
        },
        Costs = {Stat = 5700, Knowledge = 534, Social = 511, Hunt = 544, Passive = 520, BreachForm = 9975},
        ManagementTips = {}
    },
    ["Yin"] = {
        Description = "Sisi gelap dari keseimbangan. Sifat agresifnya membuatnya menakutkan.",
        DangerClass = "XII",
        BaseMood = 45,
        WorkResults = {
            Knowledge = {Success = 0.75, Crucible = 85, MoodChange = 10, MoodRequirement = 10},
            Social = {Success = 0.2, Crucible = 20, MoodChange = -15, MoodRequirement = 5},
            Hunt = {Success = 0.8, Crucible = 100, MoodChange = 20, MoodRequirement = 50},
            Passive = {Success = 0.1, Crucible = 35, MoodChange = -20, MoodRequirement = 5}
        },
        BreachChance = 0.03,
        BreachForm = {
            Name = "Pembuat Ketidakseimbangan",
            Health = 750,
            M1Damage = 75,
            Abilities = {"Serangan Bayangan", "Vortex Gelap"}
        },
        LinkedAnomaly = "Yang",
        Costs = {Stat = 500, Knowledge = 175, Social = 120, Hunt = 180, Passive = 111, BreachForm = 900, Management = {900, 950}, MXWeapon = 4500, MXArmor = 4950},
        ManagementTips = {"Ia membenci Yang. Sangat. Ia akan menyerangnya jika ia melanggar.", "Jika Yin melanggar, begitu juga Yang."},
        MXWeapon = {Name = "Pengganggu Kekacauan", Damage = 1600, Chance = 0.012, MinLevel = 4, MaxLevel = 5},
        MXArmor = {Name = "Selubung Gelap", Health = 5800, Chance = 0.006, MinLevel = 4, MaxLevel = 5}
    },
    ["Yang"] = {
        Description = "Sisi terang dari keseimbangan. Sifat pasifnya yang membuatnya dicintai.",
        DangerClass = "X",
        BaseMood = 100,
        NoMoodMeter = true,
        WorkResults = {
            Knowledge = {Success = 1.0, Crucible = 125, MoodChange = 0},
            Social = {Success = 1.0, Crucible = 100, MoodChange = 0},
            Hunt = {Success = 1.0, Crucible = 0, MoodChange = 0},
            Passive = {Success = 1.0, Crucible = 200, MoodChange = 0}
        },
        BreachChance = 0,
        BreachForm = {
            Name = "Penyimbang",
            Health = 800,
            M1Damage = 50,
            Abilities = {"Penyembuhan Cahaya", "Pemulihan Keseimbangan"}
        },
        LinkedAnomaly = "Yin",
        BreachOnLinkedBreach = true,
        Costs = {Stat = 750, Knowledge = 100, Social = 100, Hunt = 5, Passive = 100, BreachForm = 1750, Management = {1500, 1750, 1900}, MXWeapon = 4500, MXArmor = 4950},
        ManagementTips = {"Ia membenci Yin sangat.", "Setiap kali Yin mencoba melanggar, ia juga akan melanggar.", "Perannya sebagai Pelindung atau Pahlawan. Ia akan menyerang Yin SAJA bukan anomali lain."},
        MXWeapon = {Name = "Pembuat Perdamaian", Damage = 1500, Chance = 0.01, MinLevel = 4, MaxLevel = 5},
        MXArmor = {Name = "Ilahi Putih", Health = 5599, Chance = 0.005, MinLevel = 4, MaxLevel = 5}
    },
    ["ERROR"] = {
        Description = "ERROR 404 FILE NOT FOUND.",
        DangerClass = "XIV",
        BaseMood = 10,
        HideMoodValue = true,
        WorkResults = {
            Knowledge = {Success = 0.2, Crucible = 3000, MoodChange = -30, MoodRequirement = 10, AttackOnFail = true, FailDamage = 100},
            Social = {Success = 0.05, Crucible = 5700, MoodChange = -40, MoodRequirement = 5, AttackOnFail = true, FailDamage = 100},
            Hunt = {Success = 0.3, Crucible = 3500, MoodChange = -25, MoodRequirement = 20, AttackOnFail = true, FailDamage = 100},
            Passive = {Success = 0.05, Crucible = 4000, MoodChange = -35, MoodRequirement = 5, AttackOnFail = true, FailDamage = 100}
        },
        BreachChance = 0.08,
        BreachForm = {
            Name = "[ERROR 404 : kesalahan tak terduga saat mengurai kode]",
            Health = 15000,
            M1Damage = 500,
            Abilities = {"Korupsi Sistem", "Hapus Data", "Gangguan Realitas", "Pengecualian Fatal"}
        },
        Costs = {Stat = 7500, Knowledge = 500, Social = 500, Hunt = 500, Passive = 500, BreachForm = 17500},
        ManagementTips = {}
    },
    ["DAGING BERANTAKAN"] = {
        Description = "IZINKAN AKU MEMAKAI KULITMU.",
        DangerClass = "XIV",
        BaseMood = 50,
        WorkResults = {
            Knowledge = {Success = 0.1, Crucible = 205, MoodChange = 5},
            Social = {Success = 0.05, Crucible = 150, MoodChange = -10},
            Hunt = {Success = 0.4, Crucible = 350, MoodChange = 45},
            Passive = {Success = 0.2, Crucible = 500, MoodChange = -5}
        },
        BreachChance = 0.06,
        BreachForm = {
            Name = "PENGACAK",
            Health = 14500,
            M1Damage = 450,
            Abilities = {"Asimilasi Daging", "Penyusunan Ulang Kacau"}
        },
        Special = "MeatMess",
        Costs = {Stat = 5300, Knowledge = 530, Social = 555, Hunt = 580, Passive = 475, BreachForm = 13500, Management = {10000}, MXWeapon = 25000, MXArmor = 27500},
        ManagementTips = {"Setiap kali membunuh pekerja selama kerja, Ia akan meningkatkan kesehatannya."},
        MXWeapon = {Name = "Kecemburuan", Damage = 4500, Chance = 0.005, MinLevel = 5, MaxLevel = 5},
        MXArmor = {Name = "Kemarahan", Health = 8500, Chance = 0.001, MinLevel = 5, MaxLevel = 5}
    },
    ["Raja Kerangka"] = {
        Description = "Yang menguasai kerangka tak terhitung, Yang terjebak di sini selama puluhan tahun setelah secara tidak sengaja mempercayai ilusi. Apakah kau akan bergabung dengan pasukan, manusia biasa, dan menjadi pasukanku?",
        DangerClass = "XIII",
        BaseMood = 30,
        WorkResults = {
            Knowledge = {Success = 0.6, Crucible = 100, MoodChange = 5},
            Social = {Success = 0.5, Crucible = 95, MoodChange = 10},
            Hunt = {Success = 0.6, Crucible = 120, MoodChange = 30},
            Passive = {Success = 0.3, Crucible = 70, MoodChange = 5}
        },
        BreachChance = 0.035,
        BreachForm = {
            Name = "Monarki Kerangka",
            Health = 6500,
            M1Damage = 100,
            Abilities = {"Panggil Pasukan", "Perintah Tulang"}
        },
        Special = "SkeletonKing",
        Costs = {Stat = 1200, Knowledge = 260, Social = 250, Hunt = 260, Passive = 230, BreachForm = 5200, Management = {7500}, MXWeapon = 9100, MXArmor = 10500},
        ManagementTips = {"Selama pelanggaran, Setiap 30 detik seorang penjaga atau pekerja akan berubah menjadi kerangka dan bergabung dengan pasukan."},
        MXWeapon = {Name = "Pemanen Jiwa", Damage = 4000, Chance = 0.005, MinLevel = 5, MaxLevel = 5},
        MXArmor = {Name = "Tulang Abadi", Health = 8000, Chance = 0.001, MinLevel = 5, MaxLevel = 5}
    },
    ["Radio Layu Tua"] = {
        Description = "Ini adalah rekaman yang tidak boleh kita lupakan selamanya.",
        DangerClass = "XII",
        BaseMood = 50,
        WorkResults = {
            Knowledge = {Success = 0.5, Crucible = 50, MoodChange = -5},
            Social = {Success = 0.4, Crucible = 65, MoodChange = 5},
            Hunt = {Success = 0.75, Crucible = 75, MoodChange = 35},
            Passive = {Success = 0.2, Crucible = 35, MoodChange = -10}
        },
        BreachChance = 0.02,
        BreachForm = {
            Name = "GHz 7500",
            Health = 10,
            M1Damage = 80,
            Abilities = {"Beban Frekuensi", "Distorsi Sinyal"}
        },
        Special = "Radio",
        Costs = {Stat = 510, Knowledge = 140, Social = 125, Hunt = 163, Passive = 105, BreachForm = 1100, Enemies = 800, Management = {1300, 1750}, MXWeapon = 4757, MXArmor = 5000},
        ManagementTips = {"Ketika melanggar, ia akan memanggil 3 minionnya yang menyerang penjaga.", "GHz 7500 juga dikenal sebagai Radio Layu Tua adalah komandan untuk Pasukan."},
        EnemyInfo = "Pasukan Musuh: kHz 1750, Kesehatan: 100, Kerusakan M1: 10",
        MXWeapon = {Name = "Pembunyian Telinga", Damage = 610, Chance = 0.05, MinLevel = 3, MaxLevel = 5},
        MXArmor = {Name = "Setelan Operator Radio", Health = 1200, Chance = 0.03, MinLevel = 3, MaxLevel = 5}
    },
    ["Ada Mata di Dinding"] = {
        Description = "BERHENTI MENATAP AKU DENGAN MENGERIKAN",
        DangerClass = "XII",
        BaseMood = 45,
        WorkResults = {
            Knowledge = {Success = 0.3, Crucible = 50, MoodChange = 10},
            Social = {Success = 0.4, Crucible = 45, MoodChange = 5},
            Hunt = {Success = 0.5, Crucible = 75, MoodChange = 20},
            Passive = {Success = 0.1, Crucible = 35, MoodChange = -10}
        },
        BreachChance = 0.02,
        BreachForm = {
            Name = "Sebarkan Rumor",
            Health = 10,
            M1Damage = 50,
            Abilities = {"Proliferasi Mata", "Jaringan Bisikan"}
        },
        Special = "Eyes",
        Costs = {Stat = 523, Knowledge = 133, Social = 144, Hunt = 155, Passive = 111, BreachForm = 1015, Management = {1750}},
        ManagementTips = {"Ketika melanggar setiap 10 detik mata baru muncul masing-masing memiliki kesehatan 10."}
    },
    ["Toples Darah"] = {
        Description = "Toples ini berisi semua dendam di dunia.",
        DangerClass = "X",
        BaseMood = 50,
        WorkResults = {
            Knowledge = {Success = 0.7, Crucible = 10, MoodChange = 7},
            Social = {Success = 0.5, Crucible = 27, MoodChange = 12},
            Hunt = {Success = 0.3, Crucible = 50, MoodChange = 25},
            Passive = {Success = 0.5, Crucible = 30, MoodChange = 5}
        },
        BreachChance = 0,
        BreachForm = nil,
        NoBreach = true,
        Special = "JarOfBlood",
        IsInanimate = true,
        Costs = {Stat = 125, Knowledge = 70, Social = 50, Hunt = 30, Passive = 50, Management = {188, 200, 250}},
        ManagementTips = {"Ia tidak bisa kabur karena merupakan Objek Tak Bernyawa.", "Setiap Pekerjaan selesai ia akan merusak inti berdasarkan mood. Semakin rendah semakin banyak kerusakan yang ditimbulkan, Tapi semakin tinggi semakin rendah kerusakan yang ditimbulkan.", "Jika pekerja yang mengerjakannya, ia akan merusak Pekerja. Logika yang sama."}
    },
    ["Pohon Darah Mekar"] = {
        Description = "Lihat betapa indahnya mekar! Dan daunnya membakar kulitku dan aku menyukainya!",
        DangerClass = "XII",
        BaseMood = 75,
        WorkResults = {
            Knowledge = {Success = 0.5, Crucible = 100, MoodChange = 5, MoodRequirement = 10},
            Social = {Success = 0.25, Crucible = 235, MoodChange = -5, MoodRequirement = 0},
            Hunt = {Success = 0.67, Crucible = 150, MoodChange = 10, MoodRequirement = 30},
            Passive = {Success = 0.1, Crucible = 450, MoodChange = -10, MoodRequirement = 10}
        },
        BreachChance = 0,
        BreachForm = nil,
        NoBreach = true,
        IsInanimate = true,
        Special = "BloomingBloodTree",
        Costs = {Stat = 555, Knowledge = 189, Social = 140, Hunt = 140, Passive = 135, Management = {999, 1500}},
        ManagementTips = {"Hati-hati dengan pekerjaan sukses; setelah 5, pekerja mati dan berubah menjadi bunga.", "Sebagai pohon, ia tidak bisa melanggar, tapi mood rendah membunuh pekerja."}
    },
    ["Pangeran Kemasyhuran"] = {
        Description = "Atas nama Keadilan! Semua kejahatan akan dihukum!",
        DangerClass = "XIII",
        BaseMood = 50,
        WorkResults = {
            Knowledge = {Success = 0.5, Crucible = 300, MoodChange = 5, MoodRequirement = 5},
            Social = {Success = 0.7, Crucible = 450, MoodChange = 10, MoodRequirement = 25},
            Hunt = {Success = 0.2, Crucible = 100, MoodChange = -10, MoodRequirement = 5},
            Passive = {Success = 0.8, Crucible = 400, MoodChange = 15, MoodRequirement = 15}
        },
        BreachChance = 0.03,
        BreachForm = {
            Name = "Pencari Kemasyhuran",
            Health = 1500,
            M1Damage = 275,
            Abilities = {"Serangan Keadilan"}
        },
        Special = "PrinceOfFame",
        Costs = {Stat = 1205, Knowledge = 350, Social = 377, Hunt = 328, Passive = 301, BreachForm = 5410, Management = {5550, 5900, 6230}, MXWeapon = 10500, MXArmor = 12300},
        ManagementTips = {"Membantu dalam menahan pelanggaran lain dengan menyerangnya.", "Jika tidak ada pelanggaran selama 10 menit, mood berkurang dua kali lebih cepat dan pekerjaan selalu gagal.", "Pada mood 0, masuk mode bosan dengan mood 100; pada 0 di mode bosan, melanggar."},
        MXWeapon = {Name = "Penghukum", Damage = 2589, Chance = 0.015, MinLevel = 4, MaxLevel = 5},
        MXArmor = {Name = "Daya Tarik Kemasyhuran", Health = 5100, Chance = 0.01, MinLevel = 4, MaxLevel = 5}
    }
}

-- Fungsi Pembantu
local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties) do
        if k ~= "Parent" then
            instance[k] = v
        end
    end
    instance.Parent = properties.Parent
    return instance
end

local function GetRandomWorkerName()
    return GameData.WorkerNames[math.random(#GameData.WorkerNames)]
end

local function GetRandomGuardName()
    return GameData.GuardNames[math.random(#GameData.GuardNames)]
end

local function UpdateCrucible(amount)
    GameData.Crucible = GameData.Crucible + amount
    if amount > 0 then
        GameData.DailyCrucible = GameData.DailyCrucible + amount
    end
end

local function RefreshCrucibleDisplay()
    if CrucibleLabel then
        CrucibleLabel.Text = "Crucible: " .. GameData.Crucible
    end
end

local function UpdateQuotaDisplay()
    if QuotaLabel then
        local quota = GameData.CurrentDay <= #Quotas and Quotas[GameData.CurrentDay] or Quotas[#Quotas]
        QuotaLabel.Text = "Kuota: " .. GameData.DailyCrucible .. " / " .. quota
        if GameData.DailyCrucible >= quota then
            EndDayButton.Active = true
            EndDayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            EndDayButton.Active = false
            EndDayButton.TextColor3 = Color3.fromRGB(100, 100, 100)
        end
    end
end

local function getDangerLevel(class)
    local map = {
        ["X"] = 10,
        ["XI"] = 11,
        ["XII"] = 12,
        ["XIII"] = 13,
        ["XIV"] = 14
    }
    return map[class] or 0
end

local function UpdateRoomDisplay(anomalyInstance)
    local roomFrame = anomalyInstance.RoomFrame
    if not roomFrame then return end

    local unlocked = anomalyInstance.Unlocked

    local moodLabel = roomFrame:FindFirstChild("MoodLabel")
    local moodBar = roomFrame:FindFirstChild("MoodBar")
    if moodLabel then
        if anomalyInstance.Data.HideMoodValue then
            moodLabel.Text = "Mood: [ERROR]"
        elseif anomalyInstance.Data.NoMoodMeter then
            moodLabel.Text = "Mood: ∞ (Selalu Damai)"
        else
            moodLabel.Text = "Mood: " .. anomalyInstance.CurrentMood .. "/100"
        end
    end
    if moodBar then
        if anomalyInstance.Data.NoMoodMeter then
            moodBar.Size = UDim2.new(1, -10, 0, 8)
            moodBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        else
            local moodColor = anomalyInstance.CurrentMood > 50 and Color3.fromRGB(50, 150, 50) or 
                             anomalyInstance.CurrentMood > 20 and Color3.fromRGB(200, 150, 50) or 
                             Color3.fromRGB(200, 50, 50)
            TweenService:Create(moodBar, TweenInfo.new(0.3), {
                Size = UDim2.new(anomalyInstance.CurrentMood / 100, -10, 0, 8),
                BackgroundColor3 = moodColor
            }):Play()
        end
    end

    local workedByLabel = roomFrame:FindFirstChild("WorkedByLabel")
    if workedByLabel then
        workedByLabel.Text = "Dikerjakan oleh: " .. (anomalyInstance.AssignedWorker and anomalyInstance.AssignedWorker.Name or "___")
    end

    local guardedByLabel = roomFrame:FindFirstChild("GuardedByLabel")
    if guardedByLabel then
        local g1 = anomalyInstance.AssignedGuards[1] and anomalyInstance.AssignedGuards[1].Name or "___"
        local g2 = anomalyInstance.AssignedGuards[2] and anomalyInstance.AssignedGuards[2].Name or "___"
        guardedByLabel.Text = "Dijaga oleh: " .. g1 .. " dan " .. g2
    end

    local nameLabel = roomFrame:FindFirstChild("TextLabel")
    if nameLabel then
        if anomalyInstance.IsBreached then
            nameLabel.BackgroundColor3 = Color3.fromRGB(100, 20, 20)
            nameLabel.Text = (unlocked.Stat and anomalyInstance.Name or "[Tidak Diklasifikasikan]") .. " [MELANGGAR]"
        else
            nameLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            nameLabel.Text = unlocked.Stat and anomalyInstance.Name or "[Tidak Diklasifikasikan]"
        end
    end

    local dangerLabel = roomFrame:FindFirstChild("TextLabel", true) -- mengasumsikan ini label bahaya
    if dangerLabel and dangerLabel.Text:match("Kelas Bahaya") then
        dangerLabel.Text = unlocked.Stat and "Kelas Bahaya: " .. anomalyInstance.Data.DangerClass or "Kelas Bahaya: ???"
    end

    for _, child in pairs(roomFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Name ~= "InfoButton" and child.Name ~= "ExecuteButton" then
            if anomalyInstance.IsBreached then
                child.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                child.TextColor3 = Color3.fromRGB(100, 100, 100)
                child.Active = false
            else
                child.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
                child.TextColor3 = Color3.fromRGB(255, 255, 255)
                child.Active = true
            end
        end
        if child.Name == "AssignButton" or child.Name == "ExecuteButton" then
            child.Active = not anomalyInstance.IsBreached
        end
    end
end

-- Buat GUI Utama
local MainGui = CreateInstance("ScreenGui", {
    Name = "SorchesusCompanyGUI",
    Parent = playerGui,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

-- Bilah Atas
local TopBar = CreateInstance("ScrollingFrame", {
    Name = "TopBar",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 50),
    CanvasSize = UDim2.new(0, 1500, 0, 50),
    ScrollingDirection = Enum.ScrollingDirection.X,
    ScrollBarThickness = 5,
    VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
})

local TopLayout = CreateInstance("UIListLayout", {
    Parent = TopBar,
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 20),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local CompanyName = CreateInstance("TextLabel", {
    Name = "CompanyName",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 300, 1, 0),
    Text = "PERUSAHAAN SORCHESUS",
    Font = Enum.Font.GothamBold,
    TextSize = 24,
    TextColor3 = Color3.fromRGB(200, 50, 50),
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 1
})

local EmployeeButton = CreateInstance("TextButton", {
    Name = "EmployeeButton",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 120, 1, 0),
    Text = "Karyawan",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 2
})

local OuterGuardButton = CreateInstance("TextButton", {
    Name = "OuterGuardButton",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 120, 1, 0),
    Text = "Penjaga Luar",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 3
})

local TerminatorButton = CreateInstance("TextButton", {
    Name = "TerminatorButton",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 150, 1, 0),
    Text = "Protokol Terminator",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 4
})

local InventoryButton = CreateInstance("TextButton", {
    Name = "InventoryButton",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 100, 1, 0),
    Text = "Inventaris",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 5
})

local EndDayButton = CreateInstance("TextButton", {
    Name = "EndDayButton",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 120, 1, 0),
    Text = "Akhiri Hari",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(100, 100, 100),
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 6,
    Active = false
})

local Spacer = CreateInstance("Frame", {
    Name = "Spacer",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -1350, 1, 0),
    LayoutOrder = 7
})

local CrucibleLabel = CreateInstance("TextLabel", {
    Name = "CrucibleLabel",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 200, 1, 0),
    Text = "Crucible: 100",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 215, 0),
    TextXAlignment = Enum.TextXAlignment.Right,
    LayoutOrder = 8
})

local DayLabel = CreateInstance("TextLabel", {
    Name = "DayLabel",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 100, 1, 0),
    Text = "Hari: 1",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextXAlignment = Enum.TextXAlignment.Right,
    LayoutOrder = 9
})

local QuotaLabel = CreateInstance("TextLabel", {
    Name = "QuotaLabel",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 200, 1, 0),
    Text = "Kuota: 0 / 750",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 215, 0),
    TextXAlignment = Enum.TextXAlignment.Right,
    LayoutOrder = 10
})

-- GUI Toko Karyawan
local EmployeeShop = CreateInstance("Frame", {
    Name = "EmployeeShop",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    BorderSizePixel = 3,
    BorderColor3 = Color3.fromRGB(100, 100, 100),
    Size = isMobile and UDim2.new(0.95, 0, 0.95, 0) or UDim2.new(0, 700, 0, 550),
    Position = isMobile and UDim2.new(0.025, 0, 0.025, 0) or UDim2.new(0.5, -350, 0.5, -275),
    Visible = false,
    ZIndex = 10
})

local ShopTitle = CreateInstance("TextLabel", {
    Name = "ShopTitle",
    Parent = EmployeeShop,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    Text = "TOKO KARYAWAN",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local ShopScroll = CreateInstance("ScrollingFrame", {
    Name = "ShopScroll",
    Parent = EmployeeShop,
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    Size = UDim2.new(1, -20, 1, -90),
    Position = UDim2.new(0, 10, 0, 50),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 8
})

local shopGrid = CreateInstance("UIGridLayout", {
    Parent = ShopScroll,
    CellSize = UDim2.new(isMobile and 1 or 0.5, -10, 0, 180),
    CellPadding = UDim2.new(0, 10, 0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center
})

-- Buat kartu karyawan di toko
local employees = {
    {name = "Pekerja Sial", cost = 500, hp = 60, success = 0.1, type = "Worker"},
    {name = "Pekerja Normal", cost = 850, hp = 90, success = 0.23, type = "Worker"},
    {name = "Pekerja Pintar", cost = 1750, hp = 110, success = 0.35, type = "Worker"},
    {name = "Pekerja Beruntung", cost = 2355, hp = 150, success = 0.40, type = "Worker"},
    {name = "Pekerja Lebih Pintar", cost = 3400, hp = 230, success = 0.50, type = "Worker"},
    {name = "Penjaga Lemah", cost = 900, hp = 120, damage = 25, type = "Guard", level = 1},
    {name = "Penjaga Normal", cost = 1500, hp = 175, damage = 40, type = "Guard", level = 2},
    {name = "Penjaga Kuat", cost = 2500, hp = 299, damage = 75, type = "Guard", level = 3},
    {name = "Penjaga Tangguh", cost = 5000, hp = 500, damage = 100, type = "Guard", level = 4},
    {name = "Penjaga Super", cost = 6599, hp = 850, damage = 275, type = "Guard", level = 5}
}

for i, emp in ipairs(employees) do
    local frame = CreateInstance("Frame", {
        Parent = ShopScroll,
        BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    })
    CreateInstance("UICorner", {Parent = frame})
    
    CreateInstance("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Text = emp.name,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    
    local stats = "Biaya: " .. emp.cost .. " Crucible\nKesehatan: " .. emp.hp
    if emp.type == "Worker" then
        stats = stats .. "\nKeberhasilan: " .. (emp.success * 100) .. "%"
    else
        stats = stats .. "\nKerusakan: " .. emp.damage .. "\nLevel: " .. emp.level
    end
    
    CreateInstance("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 90),
        Position = UDim2.new(0, 5, 0, 30),
        Text = stats,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    })
    
    local buyBtn = CreateInstance("TextButton", {
        Parent = frame,
        BackgroundColor3 = Color3.fromRGB(50, 150, 50),
        Size = UDim2.new(1, -10, 0, 35),
        Position = UDim2.new(0, 5, 1, -40),
        Text = "Beli",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    CreateInstance("UICorner", {Parent = buyBtn})
    
    buyBtn.MouseButton1Click:Connect(function()
        if GameData.Crucible >= emp.cost then
            UpdateCrucible(-emp.cost)
            RefreshCrucibleDisplay()
            local nameFunc = emp.type == "Worker" and GetRandomWorkerName or GetRandomGuardName
            local name = nameFunc()
            local employee = {
                Name = name,
                Type = emp.name,
                BaseHP = emp.hp,
                HP = emp.hp,
                MaxHP = emp.hp,
                AssignedTo = nil
            }
            if emp.type == "Worker" then
                employee.SuccessChance = emp.success
                table.insert(GameData.OwnedWorkers, employee)
            else
                employee.BaseDamage = emp.damage
                employee.Damage = emp.damage
                employee.Level = emp.level
                employee.EquippedWeapon = nil
                employee.EquippedArmor = nil
                table.insert(GameData.OwnedGuards, employee)
            end
            CreateNotification("Direkrut " .. name .. " (" .. emp.name .. ")", Color3.fromRGB(50, 200, 50))
        else
            CreateNotification("Crucible tidak cukup!", Color3.fromRGB(200, 50, 50))
        end
    end)
end

shopGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ShopScroll.CanvasSize = UDim2.new(0, 0, 0, shopGrid.AbsoluteContentSize.Y + 20)
end)

local CloseShopButton = CreateInstance("TextButton", {
    Name = "CloseButton",
    Parent = EmployeeShop,
    BackgroundColor3 = Color3.fromRGB(150, 50, 50),
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -35, 0, 5),
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = CloseShopButton, CornerRadius = UDim.new(0, 6)})

-- GUI Inventaris
local InventoryGui = CreateInstance("Frame", {
    Name = "InventoryGui",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    BorderSizePixel = 3,
    BorderColor3 = Color3.fromRGB(100, 100, 100),
    Size = isMobile and UDim2.new(0.95, 0, 0.95, 0) or UDim2.new(0, 700, 0, 550),
    Position = isMobile and UDim2.new(0.025, 0, 0.025, 0) or UDim2.new(0.5, -350, 0.5, -275),
    Visible = false,
    ZIndex = 10
})

local InvTitle = CreateInstance("TextLabel", {
    Name = "InvTitle",
    Parent = InventoryGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    Text = "INVENTARIS",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local CloseInvButton = CreateInstance("TextButton", {
    Name = "CloseButton",
    Parent = InventoryGui,
    BackgroundColor3 = Color3.fromRGB(150, 50, 50),
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -35, 0, 5),
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = CloseInvButton, CornerRadius = UDim.new(0, 6)})

local WeaponSection = CreateInstance("ScrollingFrame", {
    Name = "WeaponSection",
    Parent = InventoryGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    Size = UDim2.new(0.45, 0, 0.45, 0),
    Position = UDim2.new(0.02, 0, 0, 50),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6
})

local WeaponTitle = CreateInstance("TextLabel", {
    Parent = WeaponSection,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 30),
    Text = "Senjata MX",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local weaponList = CreateInstance("UIListLayout", {
    Parent = WeaponSection,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local ArmorSection = CreateInstance("ScrollingFrame", {
    Name = "ArmorSection",
    Parent = InventoryGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    Size = UDim2.new(0.45, 0, 0.45, 0),
    Position = UDim2.new(0.02, 0, 0.5, 0),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6
})

local ArmorTitle = CreateInstance("TextLabel", {
    Parent = ArmorSection,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 30),
    Text = "Armor MX",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local armorList = CreateInstance("UIListLayout", {
    Parent = ArmorSection,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local GuardSection = CreateInstance("ScrollingFrame", {
    Name = "GuardSection",
    Parent = InventoryGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    Size = UDim2.new(0.45, 0, 0.9, 0),
    Position = UDim2.new(0.53, 0, 0, 50),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6
})

local GuardTitleInv = CreateInstance("TextLabel", {
    Parent = GuardSection,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 30),
    Text = "Penjaga",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local guardListInv = CreateInstance("UIListLayout", {
    Parent = GuardSection,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local EquipButton = CreateInstance("TextButton", {
    Name = "EquipButton",
    Parent = InventoryGui,
    BackgroundColor3 = Color3.fromRGB(50, 150, 50),
    Size = UDim2.new(0, 100, 0, 35),
    Position = UDim2.new(0.4, -50, 1, -50),
    Text = "Pasang",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = EquipButton, CornerRadius = UDim.new(0, 6)})

local UnequipButton = CreateInstance("TextButton", {
    Name = "UnequipButton",
    Parent = InventoryGui,
    BackgroundColor3 = Color3.fromRGB(150, 50, 50),
    Size = UDim2.new(0, 100, 0, 35),
    Position = UDim2.new(0.6, -50, 1, -50),
    Text = "Lepas",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = UnequipButton, CornerRadius = UDim.new(0, 6)})

local selectedWeapon = nil
local selectedArmor = nil
local selectedGuard = nil

local function PopulateInventory()
    for _, child in pairs(WeaponSection:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    for _, item in ipairs(GameData.OwnedMXWeapons) do
        local btn = CreateInstance("TextButton", {
            Parent = WeaponSection,
            BackgroundColor3 = Color3.fromRGB(60, 60, 80),
            Size = UDim2.new(1, -10, 0, 40),
            Text = item.Name .. " (Lvl " .. item.MinLevel .. "-" .. item.MaxLevel .. ") Kerusakan: +" .. item.Damage .. (item.EquippedTo and " (Dipasang oleh " .. item.EquippedTo.Name .. ")" or ""),
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextWrapped = true
        })
        CreateInstance("UICorner", {Parent = btn})
        btn.MouseButton1Click:Connect(function()
            selectedWeapon = item
        end)
    end
    WeaponSection.CanvasSize = UDim2.new(0, 0, 0, weaponList.AbsoluteContentSize.Y + 50)

    for _, child in pairs(ArmorSection:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    for _, item in ipairs(GameData.OwnedMXArmors) do
        local btn = CreateInstance("TextButton", {
            Parent = ArmorSection,
            BackgroundColor3 = Color3.fromRGB(60, 60, 80),
            Size = UDim2.new(1, -10, 0, 40),
            Text = item.Name .. " (Lvl " .. item.MinLevel .. "-" .. item.MaxLevel .. ") Kesehatan: +" .. item.Health .. (item.EquippedTo and " (Dipasang oleh " .. item.EquippedTo.Name .. ")" or ""),
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextWrapped = true
        })
        CreateInstance("UICorner", {Parent = btn})
        btn.MouseButton1Click:Connect(function()
            selectedArmor = item
        end)
    end
    ArmorSection.CanvasSize = UDim2.new(0, 0, 0, armorList.AbsoluteContentSize.Y + 50)

    for _, child in pairs(GuardSection:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    for _, guard in ipairs(GameData.OwnedGuards) do
        local text = guard.Name .. " (" .. guard.Type .. " Lvl " .. guard.Level .. ") Kerusakan: " .. guard.Damage .. " Kesehatan: " .. guard.HP .. "/" .. guard.MaxHP
        if guard.EquippedWeapon then
            text = text .. "\nSenjata: " .. guard.EquippedWeapon.Name
        end
        if guard.EquippedArmor then
            text = text .. "\nArmor: " .. guard.EquippedArmor.Name
        end
        local btn = CreateInstance("TextButton", {
            Parent = GuardSection,
            BackgroundColor3 = Color3.fromRGB(60, 60, 80),
            Size = UDim2.new(1, -10, 0, 60),
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextWrapped = true
        })
        CreateInstance("UICorner", {Parent = btn})
        btn.MouseButton1Click:Connect(function()
            selectedGuard = guard
        end)
    end
    GuardSection.CanvasSize = UDim2.new(0, 0, 0, guardListInv.AbsoluteContentSize.Y + 50)
end

EquipButton.MouseButton1Click:Connect(function()
    if not selectedGuard then
        CreateNotification("Pilih penjaga!", Color3.fromRGB(200, 50, 50))
        return
    end
    local equippedSomething = false
    if selectedWeapon then
        if selectedWeapon.EquippedTo == selectedGuard then
            CreateNotification("Senjata sudah dipasang!", Color3.fromRGB(200, 50, 50))
        else
            if selectedGuard.Level < selectedWeapon.MinLevel or selectedGuard.Level > selectedWeapon.MaxLevel then
                CreateNotification("Level penjaga tidak kompatibel! Membutuhkan level " .. selectedWeapon.MinLevel .. " hingga " .. selectedWeapon.MaxLevel, Color3.fromRGB(200, 50, 50))
            else
                -- Lepas dari penjaga lama jika ada
                if selectedWeapon.EquippedTo then
                    local oldGuard = selectedWeapon.EquippedTo
                    oldGuard.Damage = oldGuard.BaseDamage
                    oldGuard.EquippedWeapon = nil
                    selectedWeapon.EquippedTo = nil
                end
                -- Lepas senjata lama dari penjaga jika ada
                if selectedGuard.EquippedWeapon then
                    selectedGuard.EquippedWeapon.EquippedTo = nil
                    selectedGuard.Damage = selectedGuard.BaseDamage
                    selectedGuard.EquippedWeapon = nil
                end
                -- Pasang baru
                selectedGuard.EquippedWeapon = selectedWeapon
                selectedWeapon.EquippedTo = selectedGuard
                selectedGuard.Damage = selectedGuard.BaseDamage + selectedWeapon.Damage
                equippedSomething = true
            end
        end
    end
    if selectedArmor then
        if selectedArmor.EquippedTo == selectedGuard then
            CreateNotification("Armor sudah dipasang!", Color3.fromRGB(200, 50, 50))
        else
            if selectedGuard.Level < selectedArmor.MinLevel or selectedGuard.Level > selectedArmor.MaxLevel then
                CreateNotification("Level penjaga tidak kompatibel! Membutuhkan level " .. selectedArmor.MinLevel .. " hingga " .. selectedArmor.MaxLevel, Color3.fromRGB(200, 50, 50))
            else
                -- Lepas dari penjaga lama jika ada
                if selectedArmor.EquippedTo then
                    local oldGuard = selectedArmor.EquippedTo
                    oldGuard.MaxHP = oldGuard.BaseHP
                    oldGuard.HP = math.min(oldGuard.HP, oldGuard.MaxHP)
                    oldGuard.EquippedArmor = nil
                    selectedArmor.EquippedTo = nil
                end
                -- Lepas armor lama dari penjaga jika ada
                if selectedGuard.EquippedArmor then
                    selectedGuard.EquippedArmor.EquippedTo = nil
                    selectedGuard.MaxHP = selectedGuard.BaseHP
                    selectedGuard.HP = math.min(selectedGuard.HP, selectedGuard.MaxHP)
                    selectedGuard.EquippedArmor = nil
                end
                -- Pasang baru
                selectedGuard.EquippedArmor = selectedArmor
                selectedArmor.EquippedTo = selectedGuard
                selectedGuard.MaxHP = selectedGuard.BaseHP + selectedArmor.Health
                selectedGuard.HP = math.min(selectedGuard.HP, selectedGuard.MaxHP)
                equippedSomething = true
            end
        end
    end
    if equippedSomething then
        CreateNotification("Item dipasang ke " .. selectedGuard.Name, Color3.fromRGB(50, 200, 50))
        PopulateInventory()
    end
end)

UnequipButton.MouseButton1Click:Connect(function()
    if not selectedGuard then
        CreateNotification("Pilih penjaga!", Color3.fromRGB(200, 50, 50))
        return
    end
    local unequippedSomething = false
    if selectedGuard.EquippedWeapon then
        selectedGuard.EquippedWeapon.EquippedTo = nil
        selectedGuard.Damage = selectedGuard.BaseDamage
        selectedGuard.EquippedWeapon = nil
        unequippedSomething = true
    end
    if selectedGuard.EquippedArmor then
        selectedGuard.EquippedArmor.EquippedTo = nil
        selectedGuard.MaxHP = selectedGuard.BaseHP
        selectedGuard.HP = math.min(selectedGuard.HP, selectedGuard.MaxHP)
        selectedGuard.EquippedArmor = nil
        unequippedSomething = true
    end
    if unequippedSomething then
        CreateNotification("Item dilepas dari " .. selectedGuard.Name, Color3.fromRGB(50, 200, 50))
        PopulateInventory()
    end
end)

-- GUI Penugasan
local AssignGui = CreateInstance("Frame", {
    Name = "AssignGui",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    BorderSizePixel = 3,
    BorderColor3 = Color3.fromRGB(100, 100, 100),
    Size = isMobile and UDim2.new(0.95, 0, 0.95, 0) or UDim2.new(0, 600, 0, 450),
    Position = isMobile and UDim2.new(0.025, 0, 0.025, 0) or UDim2.new(0.5, -300, 0.5, -225),
    Visible = false,
    ZIndex = 10
})

local AssignTitle = CreateInstance("TextLabel", {
    Name = "AssignTitle",
    Parent = AssignGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    Text = "TUGASKAN PEKERJA & PENJAGA",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local CloseWGButton = CreateInstance("TextButton", {
    Name = "CloseWGButton",
    Parent = AssignGui,
    BackgroundColor3 = Color3.fromRGB(150, 50, 50),
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -35, 0, 5),
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    ZIndex = 11
})
CreateInstance("UICorner", {Parent = CloseWGButton, CornerRadius = UDim.new(0, 6)})

local WorkerSection = CreateInstance("ScrollingFrame", {
    Name = "WorkerSection",
    Parent = AssignGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    Size = UDim2.new(0.48, 0, 1, -100),
    Position = UDim2.new(0.01, 0, 0, 50),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6
})

local workerList = CreateInstance("UIListLayout", {
    Parent = WorkerSection,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local WorkerTitle = CreateInstance("TextLabel", {
    Parent = WorkerSection,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 30),
    Text = "Pekerja Tersedia",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local GuardSectionAssign = CreateInstance("ScrollingFrame", {
    Name = "GuardSection",
    Parent = AssignGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    Size = UDim2.new(0.48, 0, 1, -100),
    Position = UDim2.new(0.51, 0, 0, 50),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6
})

local guardListAssign = CreateInstance("UIListLayout", {
    Parent = GuardSectionAssign,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local GuardTitle = CreateInstance("TextLabel", {
    Parent = GuardSectionAssign,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 30),
    Text = "Penjaga Tersedia",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local CloseAssignButtonBottom = CreateInstance("TextButton", {
    Name = "CloseButtonBottom",
    Parent = AssignGui,
    BackgroundColor3 = Color3.fromRGB(100, 100, 100),
    Size = UDim2.new(0, 100, 0, 35),
    Position = UDim2.new(0.5, -50, 1, -50),
    Text = "Tutup",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = CloseAssignButtonBottom, CornerRadius = UDim.new(0, 6)})

-- GUI Penjaga Luar
local OuterGuardGui = CreateInstance("Frame", {
    Name = "OuterGuardGui",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    BorderSizePixel = 3,
    BorderColor3 = Color3.fromRGB(100, 100, 100),
    Size = isMobile and UDim2.new(0.95, 0, 0.95, 0) or UDim2.new(0, 600, 0, 450),
    Position = isMobile and UDim2.new(0.025, 0, 0.025, 0) or UDim2.new(0.5, -300, 0.5, -225),
    Visible = false,
    ZIndex = 10
})

local OuterGuardTitle = CreateInstance("TextLabel", {
    Name = "OuterGuardTitle",
    Parent = OuterGuardGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    Text = "TUGASKAN PENJAGA LUAR",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local CloseOuterButton = CreateInstance("TextButton", {
    Name = "CloseOuterButton",
    Parent = OuterGuardGui,
    BackgroundColor3 = Color3.fromRGB(150, 50, 50),
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -35, 0, 5),
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    ZIndex = 11
})
CreateInstance("UICorner", {Parent = CloseOuterButton, CornerRadius = UDim.new(0, 6)})

local AvailableOuterGuardSection = CreateInstance("ScrollingFrame", {
    Name = "AvailableOuterGuardSection",
    Parent = OuterGuardGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    Size = UDim2.new(0.48, 0, 1, -100),
    Position = UDim2.new(0.01, 0, 0, 50),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6
})

local availableOuterList = CreateInstance("UIListLayout", {
    Parent = AvailableOuterGuardSection,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local AvailableOuterTitle = CreateInstance("TextLabel", {
    Parent = AvailableOuterGuardSection,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 30),
    Text = "Penjaga Tersedia",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local CurrentOuterGuardSection = CreateInstance("ScrollingFrame", {
    Name = "CurrentOuterGuardSection",
    Parent = OuterGuardGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    Size = UDim2.new(0.48, 0, 1, -100),
    Position = UDim2.new(0.51, 0, 0, 50),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6
})

local currentOuterList = CreateInstance("UIListLayout", {
    Parent = CurrentOuterGuardSection,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local CurrentOuterTitle = CreateInstance("TextLabel", {
    Parent = CurrentOuterGuardSection,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 30),
    Text = "Penjaga Luar Saat Ini",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local CloseOuterBottom = CreateInstance("TextButton", {
    Name = "CloseOuterBottom",
    Parent = OuterGuardGui,
    BackgroundColor3 = Color3.fromRGB(100, 100, 100),
    Size = UDim2.new(0, 100, 0, 35),
    Position = UDim2.new(0.5, -50, 1, -50),
    Text = "Tutup",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = CloseOuterBottom, CornerRadius = UDim.new(0, 6)})

-- Tampilan Inti Pecahan Kosmik
local CoreFrame = CreateInstance("Frame", {
    Name = "CoreFrame",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 30),
    BorderSizePixel = 2,
    BorderColor3 = Color3.fromRGB(100, 200, 255),
    Size = UDim2.new(0.28, -20, 0.25, 0),
    Position = UDim2.new(0.72, 0, 0.5, 10)
})

CreateInstance("UICorner", {Parent = CoreFrame, CornerRadius = UDim.new(0, 10)})

local CoreTitle = CreateInstance("TextLabel", {
    Name = "CoreTitle",
    Parent = CoreFrame,
    BackgroundColor3 = Color3.fromRGB(30, 30, 50),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    Text = "INTI PECAHAN KOSMIK",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(150, 220, 255)
})

CreateInstance("UICorner", {Parent = CoreTitle, CornerRadius = UDim.new(0, 10)})

local CoreHealthLabel = CreateInstance("TextLabel", {
    Name = "CoreHealthLabel",
    Parent = CoreFrame,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 50),
    Text = "Kesehatan: 15700 / 15700",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextXAlignment = Enum.TextXAlignment.Center
})

local CoreHealthBarBG = CreateInstance("Frame", {
    Name = "CoreHealthBarBG",
    Parent = CoreFrame,
    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
    BorderSizePixel = 0,
    Size = UDim2.new(1, -20, 0, 25),
    Position = UDim2.new(0, 10, 0, 85)
})

CreateInstance("UICorner", {Parent = CoreHealthBarBG, CornerRadius = UDim.new(0, 8)})

local CoreHealthBar = CreateInstance("Frame", {
    Name = "CoreHealthBar",
    Parent = CoreHealthBarBG,
    BackgroundColor3 = Color3.fromRGB(100, 200, 255),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0)
})

CreateInstance("UICorner", {Parent = CoreHealthBar, CornerRadius = UDim.new(0, 8)})

local CoreStatusLabel = CreateInstance("TextLabel", {
    Name = "CoreStatusLabel",
    Parent = CoreFrame,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 120),
    Text = "STATUS: DILINDUNGI",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(100, 255, 100),
    TextXAlignment = Enum.TextXAlignment.Center
})

-- Kontainer Peringatan Pelanggaran
local BreachAlertContainer = CreateInstance("Frame", {
    Name = "BreachAlertContainer",
    Parent = MainGui,
    BackgroundTransparency = 1,
    Size = UDim2.new(0.28, -20, 0.15, 0),
    Position = UDim2.new(0.72, 0, 0.77, 0)
})

-- Kontainer Anomali
local AnomalyContainer = CreateInstance("ScrollingFrame", {
    Name = "AnomalyContainer",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
    BorderSizePixel = 2,
    BorderColor3 = Color3.fromRGB(50, 50, 50),
    Size = UDim2.new(0.7, -20, 0.85, -20),
    Position = UDim2.new(0, 10, 0, 60),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 10
})

CreateInstance("UIGridLayout", {
    Parent = AnomalyContainer,
    CellSize = UDim2.new(isMobile and 1 or 0.5, -10, 0, 360),
    CellPadding = UDim2.new(0, 10, 0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})

-- Panel Kereta Putih
local TrainPanel = CreateInstance("Frame", {
    Name = "TrainPanel",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(25, 25, 35),
    BorderSizePixel = 2,
    BorderColor3 = Color3.fromRGB(100, 100, 150),
    Size = UDim2.new(0.28, -20, 0.4, 0),
    Position = UDim2.new(0.72, 0, 0, 60)
})

local TrainTitle = CreateInstance("TextLabel", {
    Name = "TrainTitle",
    Parent = TrainPanel,
    BackgroundColor3 = Color3.fromRGB(35, 35, 50),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    Text = "KERETA PUTIH",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local TrainStatus = CreateInstance("TextLabel", {
    Name = "TrainStatus",
    Parent = TrainPanel,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 50),
    Text = "Datang dalam 20:00...",
    Font = Enum.Font.Gotham,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(200, 200, 200),
    TextXAlignment = Enum.TextXAlignment.Left
})

local BuyDocButton = CreateInstance("TextButton", {
    Name = "BuyDocButton",
    Parent = TrainPanel,
    BackgroundColor3 = Color3.fromRGB(80, 50, 120),
    BorderSizePixel = 0,
    Size = UDim2.new(1, -20, 0, 50),
    Position = UDim2.new(0, 10, 0, 90),
    Text = "Dapatkan 3 Dokumen (-100 Crucible)",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Visible = false
})

CreateInstance("UICorner", {Parent = BuyDocButton, CornerRadius = UDim.new(0, 8)})

local TrainTimer = CreateInstance("TextLabel", {
    Name = "TrainTimer",
    Parent = TrainPanel,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 150),
    Text = "",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 100, 100),
    Visible = false
})

-- GUI Seleksi Dokumen
local DocumentGui = CreateInstance("Frame", {
    Name = "DocumentGui",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    BorderSizePixel = 3,
    BorderColor3 = Color3.fromRGB(100, 100, 100),
    Size = isMobile and UDim2.new(0.95, 0, 0.95, 0) or UDim2.new(0, 600, 0, 450),
    Position = isMobile and UDim2.new(0.025, 0, 0.025, 0) or UDim2.new(0.5, -300, 0.5, -225),
    Visible = false,
    ZIndex = 10
})

local DocTitle = CreateInstance("TextLabel", {
    Name = "DocTitle",
    Parent = DocumentGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    Text = "PILIH DOKUMEN ANOMALI",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local DocContainer = CreateInstance("Frame", {
    Name = "DocContainer",
    Parent = DocumentGui,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -40, 0, 100),
    Position = UDim2.new(0, 20, 0, 60)
})

local docGrid = CreateInstance("UIGridLayout", {
    Parent = DocContainer,
    CellSize = UDim2.new(0.333, -10, 1, -10),
    CellPadding = UDim2.new(0, 10, 0, 0),
    SortOrder = Enum.SortOrder.LayoutOrder,
    FillDirection = Enum.FillDirection.Horizontal
})

for i = 1, 3 do
    local docBtn = CreateInstance("TextButton", {
        Name = "Document" .. i,
        Parent = DocContainer,
        BackgroundColor3 = Color3.fromRGB(50, 50, 60),
        BorderSizePixel = 2,
        BorderColor3 = Color3.fromRGB(100, 100, 120),
        Text = "Dokumen " .. i,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    CreateInstance("UICorner", {Parent = docBtn, CornerRadius = UDim.new(0, 8)})
end

local AnomalyInfo = CreateInstance("Frame", {
    Name = "AnomalyInfo",
    Parent = DocumentGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 2,
    BorderColor3 = Color3.fromRGB(70, 70, 70),
    Size = UDim2.new(1, -40, 0, 160),
    Position = UDim2.new(0, 20, 0, 160),
    Visible = false
})

local AnomalyNameLabel = CreateInstance("TextLabel", {
    Name = "AnomalyNameLabel",
    Parent = AnomalyInfo,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 5),
    Text = "",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 200, 100),
    TextXAlignment = Enum.TextXAlignment.Left
})

local DangerClassLabel = CreateInstance("TextLabel", {
    Name = "DangerClassLabel",
    Parent = AnomalyInfo,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 25),
    Position = UDim2.new(0, 10, 0, 40),
    Text = "",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 100, 100),
    TextXAlignment = Enum.TextXAlignment.Left
})

local DescriptionLabel = CreateInstance("TextLabel", {
    Name = "DescriptionLabel",
    Parent = AnomalyInfo,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 50),
    Position = UDim2.new(0, 10, 0, 70),
    Text = "",
    Font = Enum.Font.Gotham,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(200, 200, 200),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true
})

local AcceptButton = CreateInstance("TextButton", {
    Name = "AcceptButton",
    Parent = AnomalyInfo,
    BackgroundColor3 = Color3.fromRGB(50, 150, 50),
    Size = UDim2.new(0, 120, 0, 35),
    Position = UDim2.new(0, 10, 0, 125),
    Text = "Terima",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = AcceptButton, CornerRadius = UDim.new(0, 6)})

local DeclineButton = CreateInstance("TextButton", {
    Name = "DeclineButton",
    Parent = AnomalyInfo,
    BackgroundColor3 = Color3.fromRGB(150, 50, 50),
    Size = UDim2.new(0, 120, 0, 35),
    Position = UDim2.new(0, 140, 0, 125),
    Text = "Tolak",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = DeclineButton, CornerRadius = UDim.new(0, 6)})

local CloseDocButton = CreateInstance("TextButton", {
    Name = "CloseButton",
    Parent = DocumentGui,
    BackgroundColor3 = Color3.fromRGB(100, 100, 100),
    Size = UDim2.new(0, 100, 0, 35),
    Position = UDim2.new(0.5, -50, 1, -50),
    Text = "Tutup",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = CloseDocButton, CornerRadius = UDim.new(0, 6)})

local RerollButton = CreateInstance("TextButton", {
    Name = "RerollButton",
    Parent = DocumentGui,
    BackgroundColor3 = Color3.fromRGB(100,100,150),
    Size = UDim2.new(0,100,0,35),
    Position = UDim2.new(0.5,60,1,-50),
    Text = "Reroll (100)",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255,255,255)
})
CreateInstance("UICorner", {Parent = RerollButton})

-- Fungsi
local function RollForMXGift(anomalyInstance)
    local data = anomalyInstance.Data
    if data.MXWeapon and math.random() < data.MXWeapon.Chance then
        local item = {
            Name = data.MXWeapon.Name,
            Damage = data.MXWeapon.Damage,
            MinLevel = data.MXWeapon.MinLevel,
            MaxLevel = data.MXWeapon.MaxLevel,
            Type = "Weapon",
            Anomaly = anomalyInstance.Name,
            EquippedTo = nil
        }
        table.insert(GameData.OwnedMXWeapons, item)
        CreateNotification("Memperoleh Senjata MX: " .. item.Name .. "!", Color3.fromRGB(50, 200, 50))
    end
    if data.MXArmor and math.random() < data.MXArmor.Chance then
        local item = {
            Name = data.MXArmor.Name,
            Health = data.MXArmor.Health,
            MinLevel = data.MXArmor.MinLevel,
            MaxLevel = data.MXArmor.MaxLevel,
            Type = "Armor",
            Anomaly = anomalyInstance.Name,
            EquippedTo = nil
        }
        table.insert(GameData.OwnedMXArmors, item)
        CreateNotification("Memperoleh Armor MX: " .. item.Name .. "!", Color3.fromRGB(50, 200, 50))
    end
end

local function StartWorkerLoop(worker, anomalyInstance)
    spawn(function()
        while worker.AssignedTo == anomalyInstance and worker.HP > 0 and not anomalyInstance.IsBreached do
            wait(5)
            local oldMood = anomalyInstance.CurrentMood
            local success = math.random() < worker.SuccessChance
            local moodChange = success and 15 or -10
            anomalyInstance.CurrentMood = math.clamp(anomalyInstance.CurrentMood + moodChange, 0, 100)
            if success then
                UpdateCrucible(20)
                RefreshCrucibleDisplay()
                UpdateQuotaDisplay()
                RollForMXGift(anomalyInstance)
                if anomalyInstance.Name == "Pohon Darah Mekar" then
                    anomalyInstance.SuccessfulWorkerWorks = (anomalyInstance.SuccessfulWorkerWorks or 0) + 1
                    if anomalyInstance.SuccessfulWorkerWorks >= 5 then
                        worker.HP = 0
                        GameData.WorkersDied = GameData.WorkersDied + 1
                        CreateNotification(worker.Name .. " mekar menjadi bunga bernoda darah dan mati!", Color3.fromRGB(200, 50, 50))
                        anomalyInstance.AssignedWorker = nil
                        worker.AssignedTo = nil
                        anomalyInstance.SuccessfulWorkerWorks = 0
                        UpdateRoomDisplay(anomalyInstance)
                        break
                    end
                end
            end
            UpdateRoomDisplay(anomalyInstance)
            if moodChange < 0 then
                if anomalyInstance.Data.Special == "JarOfBlood" then
                    local damage = 0
                    local newMood = anomalyInstance.CurrentMood
                    if newMood <= 10 then damage = 69
                    elseif newMood <= 30 then damage = 30
                    elseif newMood <= 75 then damage = 10
                    end
                    worker.HP = math.max(0, worker.HP - damage)
                    CreateNotification(anomalyInstance.Name .. " merusak " .. worker.Name .. " sebanyak " .. damage, Color3.fromRGB(200, 50, 50))
                    if worker.HP <= 0 then
                        GameData.WorkersDied = GameData.WorkersDied + 1
                        CreateNotification(worker.Name .. " terbunuh!", Color3.fromRGB(200, 50, 50))
                        anomalyInstance.AssignedWorker = nil
                        worker.AssignedTo = nil
                        UpdateRoomDisplay(anomalyInstance)
                        break
                    end
                end
            end
            if anomalyInstance.Data.Special == "MeatMess" and anomalyInstance.CurrentMood < 30 and math.random() < 0.3 then
                if anomalyInstance.AssignedWorker then
                    anomalyInstance.AssignedWorker.HP = 0
                    GameData.WorkersDied = GameData.WorkersDied + 1
                    CreateNotification(anomalyInstance.Name .. " membunuh dan memakan " .. anomalyInstance.AssignedWorker.Name, Color3.fromRGB(200, 50, 50))
                    anomalyInstance.BonusBreachHealth = (anomalyInstance.BonusBreachHealth or 0) + 10
                    anomalyInstance.AssignedWorker = nil
                    UpdateRoomDisplay(anomalyInstance)
                end
            end
            if anomalyInstance.CurrentMood <= 0 then
                if anomalyInstance.Data.IsInanimate then
                    if anomalyInstance.AssignedWorker then
                        anomalyInstance.AssignedWorker.HP = 0
                        GameData.WorkersDied = GameData.WorkersDied + 1
                        CreateNotification(anomalyInstance.Name .. " membunuh pekerja!", Color3.fromRGB(200, 50, 50))
                        anomalyInstance.AssignedWorker = nil
                        worker.AssignedTo = nil
                        anomalyInstance.CurrentMood = anomalyInstance.Data.BaseMood / 2
                        UpdateRoomDisplay(anomalyInstance)
                    end
                else
                    TriggerBreach(anomalyInstance, anomalyInstance.RoomFrame)
                end
                break
            end
            if anomalyInstance.CurrentMood < 30 and math.random() < 0.4 then
                local damage = anomalyInstance.Data.BreachForm and anomalyInstance.Data.BreachForm.M1Damage * 0.5 or 0
                worker.HP = math.max(0, worker.HP - damage)
                CreateNotification(anomalyInstance.Name .. " menyerang " .. worker.Name .. " sebanyak " .. damage, Color3.fromRGB(200, 50, 50))
                if worker.HP <= 0 then
                    GameData.WorkersDied = GameData.WorkersDied + 1
                    CreateNotification(worker.Name .. " terbunuh!", Color3.fromRGB(200, 50, 50))
                    anomalyInstance.AssignedWorker = nil
                    worker.AssignedTo = nil
                    UpdateRoomDisplay(anomalyInstance)
                    break
                end
            end
        end
    end)
end

local function PopulateAssignGui(anomalyInstance)
    AssignTitle.Text = "TUGASKAN KE " .. (anomalyInstance.Unlocked.Stat and anomalyInstance.Name or "[Tidak Diklasifikasikan]"):upper()
    
    for _, child in pairs(WorkerSection:GetChildren()) do
        if child.Name ~= "UIListLayout" and child.Name ~= "TextLabel" then
            child:Destroy()
        end
    end
    for _, child in pairs(GuardSectionAssign:GetChildren()) do
        if child.Name ~= "UIListLayout" and child.Name ~= "TextLabel" then
            child:Destroy()
        end
    end

    for _, worker in ipairs(GameData.OwnedWorkers) do
        if worker.HP > 0 and worker.AssignedTo == nil then
            local btn = CreateInstance("TextButton", {
                Parent = WorkerSection,
                BackgroundColor3 = Color3.fromRGB(60, 60, 80),
                Size = UDim2.new(1, -10, 0, 40),
                Text = worker.Name .. " (" .. worker.Type .. ") Kesehatan: " .. worker.HP .. "/" .. worker.MaxHP,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            })
            CreateInstance("UICorner", {Parent = btn})
            btn.MouseButton1Click:Connect(function()
                if anomalyInstance.AssignedWorker == nil then
                    anomalyInstance.AssignedWorker = worker
                    worker.AssignedTo = anomalyInstance
                    StartWorkerLoop(worker, anomalyInstance)
                    AssignGui.Visible = false
                    UpdateRoomDisplay(anomalyInstance)
                else
                    CreateNotification("Slot pekerja penuh!", Color3.fromRGB(200, 50, 50))
                end
            end)
        end
    end
    WorkerSection.CanvasSize = UDim2.new(0, 0, 0, workerList.AbsoluteContentSize.Y + 50)

    for _, guard in ipairs(GameData.OwnedGuards) do
        if guard.HP > 0 and guard.AssignedTo == nil then
            local btn = CreateInstance("TextButton", {
                Parent = GuardSectionAssign,
                BackgroundColor3 = Color3.fromRGB(60, 60, 80),
                Size = UDim2.new(1, -10, 0, 40),
                Text = guard.Name .. " (" .. guard.Type .. ") Kesehatan: " .. guard.HP .. "/" .. guard.MaxHP .. " Kerusakan: " .. guard.Damage,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            })
            CreateInstance("UICorner", {Parent = btn})
            btn.MouseButton1Click:Connect(function()
                if #anomalyInstance.AssignedGuards < 2 then
                    table.insert(anomalyInstance.AssignedGuards, guard)
                    guard.AssignedTo = anomalyInstance
                    AssignGui.Visible = false
                    UpdateRoomDisplay(anomalyInstance)
                else
                    CreateNotification("Slot penjaga penuh!", Color3.fromRGB(200, 50, 50))
                end
            end)
        end
    end
    GuardSectionAssign.CanvasSize = UDim2.new(0, 0, 0, guardListAssign.AbsoluteContentSize.Y + 50)
end

local function PopulateOuterGui()
    for _, child in pairs(AvailableOuterGuardSection:GetChildren()) do
        if child.Name ~= "UIListLayout" and child.Name ~= "TextLabel" then
            child:Destroy()
        end
    end
    for _, child in pairs(CurrentOuterGuardSection:GetChildren()) do
        if child.Name ~= "UIListLayout" and child.Name ~= "TextLabel" then
            child:Destroy()
        end
    end

    for _, guard in ipairs(GameData.OwnedGuards) do
        if guard.HP > 0 and guard.AssignedTo == nil then
            local btn = CreateInstance("TextButton", {
                Parent = AvailableOuterGuardSection,
                BackgroundColor3 = Color3.fromRGB(60, 60, 80),
                Size = UDim2.new(1, -10, 0, 40),
                Text = guard.Name .. " (" .. guard.Type .. ") Kesehatan: " .. guard.HP .. "/" .. guard.MaxHP .. " Kerusakan: " .. guard.Damage,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            })
            CreateInstance("UICorner", {Parent = btn})
            btn.MouseButton1Click:Connect(function()
                table.insert(GameData.OuterGuards, guard)
                guard.AssignedTo = "Outer"
                PopulateOuterGui()
            end)
        end
    end
    AvailableOuterGuardSection.CanvasSize = UDim2.new(0, 0, 0, availableOuterList.AbsoluteContentSize.Y + 50)

    for _, guard in ipairs(GameData.OuterGuards) do
        local btn = CreateInstance("TextButton", {
            Parent = CurrentOuterGuardSection,
            BackgroundColor3 = Color3.fromRGB(60, 60, 80),
            Size = UDim2.new(1, -10, 0, 40),
            Text = guard.Name .. " (" .. guard.Type .. ") Kesehatan: " .. guard.HP .. "/" .. guard.MaxHP .. " Kerusakan: " .. guard.Damage .. " (Ditugaskan)",
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        })
        CreateInstance("UICorner", {Parent = btn})
        btn.MouseButton1Click:Connect(function()
            guard.AssignedTo = nil
            for i = #GameData.OuterGuards, 1, -1 do
                if GameData.OuterGuards[i] == guard then
                    table.remove(GameData.OuterGuards, i)
                    break
                end
            end
            PopulateOuterGui()
        end)
    end
    CurrentOuterGuardSection.CanvasSize = UDim2.new(0, 0, 0, currentOuterList.AbsoluteContentSize.Y + 50)
end

local function CreateAnomalyRoom(anomalyName)
    local anomalyData = AnomalyDatabase[anomalyName]
    if not anomalyData then return end
    
    local unlocked = {
        Stat = false,
        Knowledge = false,
        Social = false,
        Hunt = false,
        Passive = false,
        BreachForm = anomalyData.BreachForm == nil,
        Enemies = anomalyData.Costs.Enemies == nil,
        Management = {}
    }
    if anomalyData.MXWeapon then
        unlocked.MXWeapon = false
    end
    if anomalyData.MXArmor then
        unlocked.MXArmor = false
    end
    for i = 1, #anomalyData.ManagementTips or 0 do
        unlocked.Management[i] = false
    end
    
    local anomalyInstance = {
        Name = anomalyName,
        CurrentMood = anomalyData.BaseMood,
        Data = anomalyData,
        AssignedWorker = nil,
        AssignedGuards = {},
        IsBreached = false,
        RoomFrame = nil,
        BonusBreachHealth = 0,
        ToBeExecuted = false,
        SuccessfulWorkerWorks = 0,
        IsBored = false,
        IsHelping = false,
        Unlocked = unlocked
    }
    
    if anomalyInstance.Data.Special == "PrinceOfFame" then
        anomalyInstance.IsBored = false
        anomalyInstance.IsHelping = false
    end
    
    table.insert(GameData.OwnedAnomalies, anomalyInstance)
    
    local roomFrame = CreateInstance("Frame", {
        Name = "AnomalyRoom_" .. #GameData.OwnedAnomalies,
        Parent = AnomalyContainer,
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BorderSizePixel = 2,
        BorderColor3 = Color3.fromRGB(80, 80, 90)
    })
    
    CreateInstance("UICorner", {Parent = roomFrame, CornerRadius = UDim.new(0, 10)})
    
    local nameLabel = CreateInstance("TextLabel", {
        Name = "TextLabel",
        Parent = roomFrame,
        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 35),
        Text = "[Tidak Diklasifikasikan]",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 200, 100),
        TextWrapped = true
    })
    
    local dangerLabel = CreateInstance("TextLabel", {
        Parent = roomFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 25),
        Position = UDim2.new(0, 5, 0, 40),
        Text = "Kelas Bahaya: ???",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 100, 100),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local moodLabel = CreateInstance("TextLabel", {
        Name = "MoodLabel",
        Parent = roomFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 70),
        Text = "Mood: " .. anomalyInstance.CurrentMood .. "/100",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local moodBar = CreateInstance("Frame", {
        Name = "MoodBar",
        Parent = roomFrame,
        BackgroundColor3 = Color3.fromRGB(50, 150, 50),
        BorderSizePixel = 0,
        Size = UDim2.new(anomalyInstance.CurrentMood / 100, -10, 0, 8),
        Position = UDim2.new(0, 5, 0, 95)
    })
    CreateInstance("UICorner", {Parent = moodBar, CornerRadius = UDim.new(0, 4)})
    
    local workedByLabel = CreateInstance("TextLabel", {
        Name = "WorkedByLabel",
        Parent = roomFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 105),
        Text = "Dikerjakan oleh: ___",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local guardedByLabel = CreateInstance("TextLabel", {
        Name = "GuardedByLabel",
        Parent = roomFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 125),
        Text = "Dijaga oleh: ___ dan ___",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local workTypes = {"Pengetahuan", "Sosial", "Berburu", "Pasif"}
    for i, workType in ipairs(workTypes) do
        local workBtn = CreateInstance("TextButton", {
            Name = workType .. "Button",
            Parent = roomFrame,
            BackgroundColor3 = Color3.fromRGB(60, 60, 80),
            BorderSizePixel = 0,
            Size = UDim2.new(0.45, -5, 0, 35),
            Position = UDim2.new((i-1) % 2 * 0.5 + 0.025, 0, 0, 150 + math.floor((i-1) / 2) * 45),
            Text = workType,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        })
        CreateInstance("UICorner", {Parent = workBtn, CornerRadius = UDim.new(0, 6)})
        
        workBtn.MouseButton1Click:Connect(function()
            PerformWork(anomalyInstance, workType, roomFrame)
        end)
    end
    
    local infoBtn = CreateInstance("TextButton", {
        Name = "InfoButton",
        Parent = roomFrame,
        BackgroundColor3 = Color3.fromRGB(80, 80, 100),
        BorderSizePixel = 0,
        Size = UDim2.new(0.95, 0, 0, 35),
        Position = UDim2.new(0.025, 0, 0, 240),
        Text = "Info",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    CreateInstance("UICorner", {Parent = infoBtn, CornerRadius = UDim.new(0, 6)})
    
    infoBtn.MouseButton1Click:Connect(function()
        ShowAnomalyInfo(anomalyInstance)
    end)
    
    local assignBtn = CreateInstance("TextButton", {
        Name = "AssignButton",
        Parent = roomFrame,
        BackgroundColor3 = Color3.fromRGB(80, 80, 100),
        BorderSizePixel = 0,
        Size = UDim2.new(0.95, 0, 0, 35),
        Position = UDim2.new(0.025, 0, 0, 280),
        Text = "Pekerja & Penjaga",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    CreateInstance("UICorner", {Parent = assignBtn, CornerRadius = UDim.new(0, 6)})
    
    assignBtn.MouseButton1Click:Connect(function()
        PopulateAssignGui(anomalyInstance)
        AssignGui.Visible = true
    end)
    
    local executeBtn = CreateInstance("TextButton", {
        Name = "ExecuteButton",
        Parent = roomFrame,
        BackgroundColor3 = Color3.fromRGB(150, 50, 50),
        BorderSizePixel = 0,
        Size = UDim2.new(0.95, 0, 0, 35),
        Position = UDim2.new(0.025, 0, 0, 320),
        Text = "Eksekusi",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    CreateInstance("UICorner", {Parent = executeBtn, CornerRadius = UDim.new(0, 6)})
    
    executeBtn.MouseButton1Click:Connect(function()
        if not anomalyInstance.IsBreached then
            anomalyInstance.ToBeExecuted = true
            TriggerBreach(anomalyInstance, roomFrame)
        end
    end)
    
    anomalyInstance.RoomFrame = roomFrame
    UpdateRoomDisplay(anomalyInstance)
    
    local function UpdateCanvasSize()
        local layout = AnomalyContainer:FindFirstChildOfClass("UIGridLayout")
        if layout then
            AnomalyContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end
    end
    
    wait(0.1)
    UpdateCanvasSize()
    
    local layout = AnomalyContainer:FindFirstChildOfClass("UIGridLayout")
    if layout then
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvasSize)
    end
end

function PerformWork(anomalyInstance, workType, roomFrame)
    local workResult = anomalyInstance.Data.WorkResults[workType]
    if not workResult then return end
    
    if workResult.MoodRequirement and anomalyInstance.CurrentMood < workResult.MoodRequirement then
        CreateNotification("Mood terlalu rendah! Minimum diperlukan: " .. workResult.MoodRequirement, Color3.fromRGB(200, 50, 50))
        return
    end
    
    if anomalyInstance.Data.NoMoodMeter then
        UpdateCrucible(workResult.Crucible)
        RefreshCrucibleDisplay()
        UpdateQuotaDisplay()
        CreateNotification("Pekerjaan Sukses! +" .. workResult.Crucible .. " Crucible", Color3.fromRGB(50, 200, 50))
        return
    end
    
    local success = math.random() < workResult.Success
    if anomalyInstance.Data.Special == "PrinceOfFame" and os.time() - GameData.LastGlobalBreachTime > 600 then
        success = false
    end
    local moodChange = 0
    
    if success then
        UpdateCrucible(workResult.Crucible)
        RefreshCrucibleDisplay()
        UpdateQuotaDisplay()
        RollForMXGift(anomalyInstance)
        moodChange = workResult.MoodChange
    else
        if workResult.AttackOnFail and anomalyInstance.AssignedWorker then
            local damage = workResult.FailDamage
            anomalyInstance.AssignedWorker.HP = math.max(0, anomalyInstance.AssignedWorker.HP - damage)
            CreateNotification(anomalyInstance.Name .. " menyerang " .. anomalyInstance.AssignedWorker.Name .. " sebanyak " .. damage, Color3.fromRGB(200, 50, 50))
            
            if anomalyInstance.AssignedWorker.HP <= 0 then
                GameData.WorkersDied = GameData.WorkersDied + 1
                CreateNotification(anomalyInstance.AssignedWorker.Name .. " terbunuh!", Color3.fromRGB(200, 50, 50))
                anomalyInstance.AssignedWorker = nil
                UpdateRoomDisplay(anomalyInstance)
            end
        end
        moodChange = math.abs(workResult.MoodChange) * 2 * -1
    end
    
    anomalyInstance.CurrentMood = math.clamp(anomalyInstance.CurrentMood + moodChange, 0, 100)
    
    if moodChange < 0 then
        if anomalyInstance.Data.Special == "JarOfBlood" then
            local damage = 0
            local newMood = anomalyInstance.CurrentMood
            if newMood <= 10 then damage = 3500
            elseif newMood <= 30 then damage = 750
            elseif newMood <= 75 then damage = 100
            end
            GameData.CosmicShardCoreHealth = math.max(0, GameData.CosmicShardCoreHealth - damage)
            CreateNotification(anomalyInstance.Name .. " merusak Inti Pecahan Kosmik sebanyak " .. damage, Color3.fromRGB(200, 50, 50))
            UpdateCoreDisplay()
        end
    end
    
    if anomalyInstance.Data.Special == "MeatMess" and anomalyInstance.CurrentMood < 30 and math.random() < 0.3 then
        if anomalyInstance.AssignedWorker then
            anomalyInstance.AssignedWorker.HP = 0
            GameData.WorkersDied = GameData.WorkersDied + 1
            CreateNotification(anomalyInstance.Name .. " membunuh dan memakan " .. anomalyInstance.AssignedWorker.Name, Color3.fromRGB(200, 50, 50))
            anomalyInstance.BonusBreachHealth = (anomalyInstance.BonusBreachHealth or 0) + 10
            anomalyInstance.AssignedWorker = nil
            UpdateRoomDisplay(anomalyInstance)
        end
    end
    
    if anomalyInstance.CurrentMood <= 0 then
        if anomalyInstance.Data.IsInanimate then
            if anomalyInstance.AssignedWorker then
                anomalyInstance.AssignedWorker.HP = 0
                GameData.WorkersDied = GameData.WorkersDied + 1
                CreateNotification(anomalyInstance.Name .. " membunuh pekerja!", Color3.fromRGB(200, 50, 50))
                anomalyInstance.AssignedWorker = nil
                anomalyInstance.CurrentMood = anomalyInstance.Data.BaseMood / 2
                UpdateRoomDisplay(anomalyInstance)
            end
        else
            TriggerBreach(anomalyInstance, roomFrame)
        end
    else
        if success then
            if math.random() < anomalyInstance.Data.BreachChance then
                TriggerBreach(anomalyInstance, roomFrame)
            end
        else
            if math.random() < (anomalyInstance.Data.BreachChance * 3) then
                TriggerBreach(anomalyInstance, roomFrame)
            end
        end
    end
    
    local moodText = moodChange >= 0 and ("+" .. moodChange) or tostring(moodChange)
    local notifText = success and ("Pekerjaan Sukses! +" .. workResult.Crucible .. " Crucible (Mood: " .. moodText .. ")") or ("Pekerjaan Gagal! Mood berkurang sebanyak " .. math.abs(moodChange))
    CreateNotification(notifText, success and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50))
    
    UpdateRoomDisplay(anomalyInstance)
end

function TriggerBreach(anomalyInstance, roomFrame)
    if anomalyInstance.IsBreached or anomalyInstance.Data.NoBreach then return end
    
    if anomalyInstance.Data.NoMoodMeter and not anomalyInstance.Data.BreachOnLinkedBreach then
        return
    end
    
    GameData.LastGlobalBreachTime = os.time()
    GameData.TotalBreaches = GameData.TotalBreaches + 1
    
    local breachData = anomalyInstance.Data.BreachForm
    anomalyInstance.IsBreached = true
    anomalyInstance.BreachHP = breachData.Health + (anomalyInstance.BonusBreachHealth or 0)
    anomalyInstance.BreachTime = os.time()
    
    table.insert(GameData.BreachedAnomalies, {
        Instance = anomalyInstance,
        BreachData = breachData,
        RoomFrame = roomFrame
    })
    
    CreateNotification("PELANGGARAN! " .. breachData.Name .. " telah kabur!", Color3.fromRGB(255, 0, 0))
    
    UpdateRoomDisplay(anomalyInstance)
    UpdateBreachAlert()
    
    if anomalyInstance.Data.LinkedAnomaly then
        for _, otherAnomaly in ipairs(GameData.OwnedAnomalies) do
            if otherAnomaly.Name == anomalyInstance.Data.LinkedAnomaly and otherAnomaly.Data.BreachOnLinkedBreach then
                CreateNotification(otherAnomaly.Name .. " merespons pelanggaran!", Color3.fromRGB(100, 200, 255))
                TriggerBreach(otherAnomaly, otherAnomaly.RoomFrame)
            end
        end
    end
    
    for _, anomaly in ipairs(GameData.OwnedAnomalies) do
        if anomaly.Name == "Pangeran Kemasyhuran" and not anomaly.IsBreached then
            anomaly.IsHelping = true
            TriggerBreach(anomaly, anomaly.RoomFrame)
            break
        end
    end
    
    StartBreachLoop(anomalyInstance)
end

function StartBreachLoop(anomalyInstance)
    spawn(function()
        local breachData = anomalyInstance.Data.BreachForm
        local isYang = anomalyInstance.Name == "Yang"
        local yinInstance = nil
        local elapsed = 0
        
        local minions = {}
        local minionDamage = 0
        local eyes = {}
        
        if anomalyInstance.Data.Special == "Radio" then
            for i = 1, 5 do
                table.insert(minions, {HP = 100})
            end
            minionDamage = 10
        end
        
        if anomalyInstance.Data.Special == "Eyes" then
            table.insert(eyes, {HP = 10})
        end
        
        if isYang then
            for _, anomaly in ipairs(GameData.OwnedAnomalies) do
                if anomaly.Name == "Yin" and anomaly.IsBreached then
                    yinInstance = anomaly
                    break
                end
            end
        end
        
        while anomalyInstance.IsBreached do
            wait(2)
            elapsed = elapsed + 2
            
            if anomalyInstance.Data.Special == "SkeletonKing" and elapsed % 30 == 0 then
                local allEmployees = {}
                for _, w in ipairs(GameData.OwnedWorkers) do
                    if w.HP > 0 then table.insert(allEmployees, w) end
                end
                for _, g in ipairs(GameData.OwnedGuards) do
                    if g.HP > 0 then table.insert(allEmployees, g) end
                end
                if #allEmployees > 0 then
                    local target = allEmployees[math.random(#allEmployees)]
                    target.HP = 0
                    if target.SuccessChance then
                        GameData.WorkersDied = GameData.WorkersDied + 1
                    else
                        GameData.GuardsDied = GameData.GuardsDied + 1
                    end
                    CreateNotification(target.Name .. " bergabung dengan pasukan kerangka!", Color3.fromRGB(200, 50, 50))
                    if target.AssignedTo then
                        if target.AssignedTo == "Outer" then
                            for i = #GameData.OuterGuards, 1, -1 do
                                if GameData.OuterGuards[i] == target then
                                    table.remove(GameData.OuterGuards, i)
                                    break
                                end
                            end
                        else
                            if target.AssignedTo.AssignedWorker == target then
                                target.AssignedTo.AssignedWorker = nil
                            end
                            for i = #target.AssignedTo.AssignedGuards, 1, -1 do
                                if target.AssignedTo.AssignedGuards[i] == target then
                                    table.remove(target.AssignedTo.AssignedGuards, i)
                                end
                            end
                            UpdateRoomDisplay(target.AssignedTo)
                        end
                    end
                    target.AssignedTo = nil
                    if target.SuccessChance then
                        for i = #GameData.OwnedWorkers, 1, -1 do
                            if GameData.OwnedWorkers[i] == target then
                                table.remove(GameData.OwnedWorkers, i)
                            end
                        end
                    else
                        for i = #GameData.OwnedGuards, 1, -1 do
                            if GameData.OwnedGuards[i] == target then
                                table.remove(GameData.OwnedGuards, i)
                            end
                        end
                    end
                end
            end
            
            if anomalyInstance.Data.Special == "Eyes" and elapsed % 5 == 0 then
                table.insert(eyes, {HP = 10})
                CreateNotification("Mata baru muncul!", Color3.fromRGB(200, 50, 50))
            end
            
            local employees = {}
            if anomalyInstance.AssignedWorker and anomalyInstance.AssignedWorker.HP > 0 then
                table.insert(employees, anomalyInstance.AssignedWorker)
            end
            for _, guard in ipairs(anomalyInstance.AssignedGuards) do
                if guard.HP > 0 then
                    table.insert(employees, guard)
                end
            end
            
            -- Kerusakan minion/mata khusus
            local extraDamage = 0
            if anomalyInstance.Data.Special == "Radio" then
                extraDamage = minionDamage * #minions
            elseif anomalyInstance.Data.Special == "Eyes" then
                extraDamage = 50 * #eyes
            end
            if extraDamage > 0 then
                if #employees > 0 then
                    local target = employees[math.random(#employees)]
                    target.HP = math.max(0, target.HP - extraDamage)
                    CreateNotification("Minion " .. anomalyInstance.Name .. " menyerang " .. target.Name .. " sebanyak " .. extraDamage, Color3.fromRGB(200, 50, 50))
                    if target.HP <= 0 then
                        if target == anomalyInstance.AssignedWorker then
                            GameData.WorkersDied = GameData.WorkersDied + 1
                        else
                            GameData.GuardsDied = GameData.GuardsDied + 1
                        end
                        CreateNotification(target.Name .. " terbunuh!", Color3.fromRGB(200, 50, 50))
                        if target == anomalyInstance.AssignedWorker then
                            anomalyInstance.AssignedWorker = nil
                        else
                            for i = #anomalyInstance.AssignedGuards, 1, -1 do
                                if anomalyInstance.AssignedGuards[i] == target then
                                    table.remove(anomalyInstance.AssignedGuards, i)
                                    break
                                end
                            end
                        end
                        target.AssignedTo = nil
                        UpdateRoomDisplay(anomalyInstance)
                    end
                else
                    local damageTarget = GameData.CosmicShardCoreHealth
                    if GameData.TerminatorActive and #GameData.TerminatorAgents > 0 then
                        local agent = GameData.TerminatorAgents[math.random(#GameData.TerminatorAgents)]
                        agent.HP = math.max(0, agent.HP - extraDamage)
                        CreateNotification("Minion " .. anomalyInstance.Name .. " menyerang " .. agent.Name .. " sebanyak " .. extraDamage, Color3.fromRGB(200, 50, 50))
                        if agent.HP <= 0 then
                            CreateNotification(agent.Name .. " jatuh!", Color3.fromRGB(200, 50, 50))
                            for i = #GameData.TerminatorAgents, 1, -1 do
                                if GameData.TerminatorAgents[i] == agent then
                                    table.remove(GameData.TerminatorAgents, i)
                                    break
                                end
                            end
                        end
                    else
                        GameData.CosmicShardCoreHealth = math.max(0, GameData.CosmicShardCoreHealth - extraDamage)
                        UpdateCoreDisplay()
                        if GameData.CosmicShardCoreHealth <= 0 then
                            CompanyDestroyed()
                            break
                        end
                    end
                end
            end
            
            if anomalyInstance.Data.Special == "PrinceOfFame" and anomalyInstance.IsHelping then
                if #GameData.BreachedAnomalies <= 1 then  -- hanya dirinya sendiri
                    anomalyInstance.IsBreached = false
                    anomalyInstance.IsHelping = false
                    anomalyInstance.CurrentMood = anomalyInstance.Data.BaseMood
                    for i, b in ipairs(GameData.BreachedAnomalies) do
                        if b.Instance == anomalyInstance then
                            table.remove(GameData.BreachedAnomalies, i)
                            break
                        end
                    end
                    UpdateRoomDisplay(anomalyInstance)
                    UpdateBreachAlert()
                    UpdateCoreDisplay()
                    break
                else
                    local targets = {}
                    for _, b in ipairs(GameData.BreachedAnomalies) do
                        if b.Instance ~= anomalyInstance then
                            table.insert(targets, b.Instance)
                        end
                    end
                    if #targets > 0 then
                        table.sort(targets, function(a, b) return getDangerLevel(a.Data.DangerClass) > getDangerLevel(b.Data.DangerClass) end)
                        local target = targets[1]
                        local damage = breachData.M1Damage
                        target.BreachHP = math.max(0, target.BreachHP - damage)
                        CreateNotification("Pencari Kemasyhuran menyerang " .. target.Data.BreachForm.Name .. " sebanyak " .. damage, Color3.fromRGB(100, 200, 255))
                        if target.BreachHP <= 0 then
                            CreateNotification(target.Data.BreachForm.Name .. " telah ditahan oleh Pencari Kemasyhuran!", Color3.fromRGB(50, 200, 50))
                            target.IsBreached = false
                            target.CurrentMood = target.Data.BaseMood / 2
                            for i, b in ipairs(GameData.BreachedAnomalies) do
                                if b.Instance == target then
                                    table.remove(GameData.BreachedAnomalies, i)
                                    break
                                end
                            end
                            UpdateRoomDisplay(target)
                        end
                    end
                end
            else
                if isYang and yinInstance then
                    if yinInstance.IsBreached and yinInstance.BreachHP > 0 then
                        local damage = breachData.M1Damage
                        yinInstance.BreachHP = math.max(0, yinInstance.BreachHP - damage)
                        CreateNotification("Penyimbang menyerang Pembuat Ketidakseimbangan sebanyak " .. damage, Color3.fromRGB(100, 200, 255))
                        
                        if yinInstance.BreachHP <= 0 then
                            CreateNotification("Pembuat Ketidakseimbangan telah ditahan oleh Penyimbang!", Color3.fromRGB(50, 200, 50))
                            yinInstance.IsBreached = false
                            yinInstance.CurrentMood = yinInstance.Data.BaseMood / 2
                            yinInstance.BreachHP = nil
                            for i, b in ipairs(GameData.BreachedAnomalies) do
                                if b.Instance == yinInstance then
                                    table.remove(GameData.BreachedAnomalies, i)
                                    break
                                end
                            end
                            UpdateRoomDisplay(yinInstance)
                            
                            anomalyInstance.IsBreached = false
                            for i, b in ipairs(GameData.BreachedAnomalies) do
                                if b.Instance == anomalyInstance then
                                    table.remove(GameData.BreachedAnomalies, i)
                                    break
                                end
                            end
                            UpdateRoomDisplay(anomalyInstance)
                            UpdateBreachAlert()
                            UpdateCoreDisplay()
                            break
                        end
                    else
                        anomalyInstance.IsBreached = false
                        for i, b in ipairs(GameData.BreachedAnomalies) do
                            if b.Instance == anomalyInstance then
                                table.remove(GameData.BreachedAnomalies, i)
                                break
                            end
                        end
                        UpdateRoomDisplay(anomalyInstance)
                        UpdateBreachAlert()
                        UpdateCoreDisplay()
                        break
                    end
                else
                    if #employees > 0 then
                        local target = employees[math.random(#employees)]
                        local damage = breachData.M1Damage
                        target.HP = math.max(0, target.HP - damage)
                        CreateNotification(breachData.Name .. " menyerang " .. target.Name .. " sebanyak " .. damage, Color3.fromRGB(200, 50, 50))
                        
                        if target.HP <= 0 then
                            if target.SuccessChance then
                                GameData.WorkersDied = GameData.WorkersDied + 1
                            else
                                GameData.GuardsDied = GameData.GuardsDied + 1
                            end
                            CreateNotification(target.Name .. " terbunuh!", Color3.fromRGB(200, 50, 50))
                            if target == anomalyInstance.AssignedWorker then
                                anomalyInstance.AssignedWorker = nil
                            else
                                for i = #anomalyInstance.AssignedGuards, 1, -1 do
                                    if anomalyInstance.AssignedGuards[i] == target then
                                        table.remove(anomalyInstance.AssignedGuards, i)
                                        break
                                    end
                                end
                            end
                            target.AssignedTo = nil
                            UpdateRoomDisplay(anomalyInstance)
                        end
                    else
                        local damage = breachData.M1Damage
                        if GameData.TerminatorActive and #GameData.TerminatorAgents > 0 then
                            local agent = GameData.TerminatorAgents[math.random(#GameData.TerminatorAgents)]
                            agent.HP = math.max(0, agent.HP - damage)
                            CreateNotification(breachData.Name .. " menyerang " .. agent.Name .. " sebanyak " .. damage, Color3.fromRGB(200, 50, 50))
                            if agent.HP <= 0 then
                                CreateNotification(agent.Name .. " jatuh!", Color3.fromRGB(200, 50, 50))
                                for i = #GameData.TerminatorAgents, 1, -1 do
                                    if GameData.TerminatorAgents[i] == agent then
                                        table.remove(GameData.TerminatorAgents, i)
                                        break
                                    end
                                end
                            end
                        else
                            GameData.CosmicShardCoreHealth = math.max(0, GameData.CosmicShardCoreHealth - damage)
                            UpdateCoreDisplay()
                            if GameData.CosmicShardCoreHealth <= 0 then
                                CompanyDestroyed()
                                break
                            end
                        end
                    end
                    
                    for _, guard in ipairs(anomalyInstance.AssignedGuards) do
                        if guard.HP > 0 then
                            local gdamage = guard.Damage
                            local attacked = false
                            if anomalyInstance.Data.Special == "Radio" and #minions > 0 then
                                minions[1].HP = math.max(0, minions[1].HP - gdamage)
                                if minions[1].HP <= 0 then
                                    table.remove(minions, 1)
                                    CreateNotification("Musuh kHz 1750 dikalahkan!", Color3.fromRGB(50, 200, 50))
                                end
                                attacked = true
                            elseif anomalyInstance.Data.Special == "Eyes" and #eyes > 0 then
                                eyes[1].HP = math.max(0, eyes[1].HP - gdamage)
                                if eyes[1].HP <= 0 then
                                    table.remove(eyes, 1)
                                    CreateNotification("Mata dihancurkan!", Color3.fromRGB(50, 200, 50))
                                end
                                attacked = true
                            end
                            if not attacked then
                                anomalyInstance.BreachHP = math.max(0, anomalyInstance.BreachHP - gdamage)
                            end
                            CreateNotification(guard.Name .. " menyerang " .. breachData.Name .. " sebanyak " .. gdamage, Color3.fromRGB(50, 200, 50))
                        end
                    end
                    
                    if anomalyInstance.Data.Special == "Eyes" and #eyes == 0 then
                        anomalyInstance.BreachHP = 0
                    elseif anomalyInstance.Data.Special == "Radio" and #minions == 0 then
                        anomalyInstance.BreachHP = 0
                    end
                    
                    if anomalyInstance.BreachHP <= 0 then
                        local wipe = anomalyInstance.ToBeExecuted  -- dihapus GameData.TerminatorActive dari kondisi wipe
                        if wipe then
                            CreateNotification(anomalyInstance.Name .. " telah dihapus selamanya!", Color3.fromRGB(255, 0, 0))
                            for i = #GameData.OwnedAnomalies, 1, -1 do
                                if GameData.OwnedAnomalies[i] == anomalyInstance then
                                    table.remove(GameData.OwnedAnomalies, i)
                                    break
                                end
                            end
                            anomalyInstance.RoomFrame:Destroy()
                        else
                            CreateNotification(breachData.Name .. " telah ditahan!", Color3.fromRGB(50, 200, 50))
                            anomalyInstance.IsBreached = false
                            anomalyInstance.CurrentMood = anomalyInstance.Data.BaseMood / 2
                            anomalyInstance.BreachHP = nil
                        end
                        for i, b in ipairs(GameData.BreachedAnomalies) do
                            if b.Instance == anomalyInstance then
                                table.remove(GameData.BreachedAnomalies, i)
                                break
                            end
                        end
                        UpdateRoomDisplay(anomalyInstance)
                        UpdateBreachAlert()
                        UpdateCoreDisplay()
                        break
                    end
                end
            end
        end
    end)
end

-- Loop Penjaga Luar
spawn(function()
    while true do
        wait(2)
        if #GameData.BreachedAnomalies > 0 then
            for _, guard in ipairs(GameData.OuterGuards) do
                if guard.HP > 0 then
                    if #GameData.BreachedAnomalies == 0 then break end
                    table.sort(GameData.BreachedAnomalies, function(a, b) return a.Instance.BreachTime < b.Instance.BreachTime end)
                    local target = GameData.BreachedAnomalies[1].Instance
                    local damage = guard.Damage
                    target.BreachHP = math.max(0, target.BreachHP - damage)
                    CreateNotification(guard.Name .. " (Luar) menyerang " .. target.Data.BreachForm.Name .. " sebanyak " .. damage, Color3.fromRGB(50, 200, 50))
                    if target.BreachHP <= 0 then
                        CreateNotification(target.Data.BreachForm.Name .. " ditahan!", Color3.fromRGB(50, 200, 50))
                        target.IsBreached = false
                        target.CurrentMood = target.Data.BaseMood / 2
                        target.BreachHP = nil
                        for i = #GameData.BreachedAnomalies, 1, -1 do
                            if GameData.BreachedAnomalies[i].Instance == target then
                                table.remove(GameData.BreachedAnomalies, i)
                                break
                            end
                        end
                        UpdateRoomDisplay(target)
                        UpdateBreachAlert()
                        UpdateCoreDisplay()
                    end
                end
            end
        elseif #GameData.RaidEntities > 0 then
            for _, guard in ipairs(GameData.OuterGuards) do
                if guard.HP > 0 then
                    local target = GameData.RaidEntities[math.random(#GameData.RaidEntities)]
                    local damage = guard.Damage
                    target.hp = math.max(0, target.hp - damage)
                    CreateNotification(guard.Name .. " (Luar) menyerang " .. target.name .. " sebanyak " .. damage, Color3.fromRGB(50, 200, 50))
                    if target.hp <= 0 then
                        CreateNotification(target.name .. " dikalahkan!", Color3.fromRGB(50, 200, 50))
                        for i = #GameData.RaidEntities, 1, -1 do
                            if GameData.RaidEntities[i] == target then
                                table.remove(GameData.RaidEntities, i)
                                break
                            end
                        end
                        if #GameData.RaidEntities == 0 then
                            ShowRaidGUI(GameData.CurrentRaid, false)
                            CreateNotification("Serangan dikalahkan!", Color3.fromRGB(50, 200, 50))
                            GameData.CurrentRaid = nil
                        end
                    end
                end
            end
        end
    end
end)

-- Loop Serangan Terminator
spawn(function()
    while true do
        wait(2)
        if GameData.TerminatorActive and #GameData.TerminatorAgents > 0 then
            if #GameData.BreachedAnomalies > 0 then
                local sorted = {}
                for _, b in ipairs(GameData.BreachedAnomalies) do
                    table.insert(sorted, b)
                end
                table.sort(sorted, function(a, b)
                    return getDangerLevel(a.Instance.Data.DangerClass) > getDangerLevel(b.Instance.Data.DangerClass)
                end)
                local target = sorted[1].Instance
                for _, agent in ipairs(GameData.TerminatorAgents) do
                    if agent.HP > 0 then
                        local damage = agent.Damage
                        target.BreachHP = math.max(0, target.BreachHP - damage)
                        CreateNotification(agent.Name .. " menyerang " .. target.Data.BreachForm.Name .. " sebanyak " .. damage, Color3.fromRGB(50, 200, 50))
                        if target.BreachHP <= 0 then
                            CreateNotification(target.Data.BreachForm.Name .. " ditahan!", Color3.fromRGB(50, 200, 50))
                            target.IsBreached = false
                            target.CurrentMood = target.Data.BaseMood / 2
                            target.BreachHP = nil
                            for i = #GameData.BreachedAnomalies, 1, -1 do
                                if GameData.BreachedAnomalies[i].Instance == target then
                                    table.remove(GameData.BreachedAnomalies, i)
                                    break
                                end
                            end
                            UpdateRoomDisplay(target)
                            UpdateBreachAlert()
                            UpdateCoreDisplay()
                            if #GameData.BreachedAnomalies == 0 and #GameData.RaidEntities == 0 then
                                GameData.TerminatorActive = false
                                GameData.TerminatorAgents = {}
                                CreateNotification("Agen terminator kembali.", Color3.fromRGB(100, 100, 255))
                            end
                        end
                    end
                end
            elseif #GameData.RaidEntities > 0 then
                local target = GameData.RaidEntities[1]
                for _, agent in ipairs(GameData.TerminatorAgents) do
                    if agent.HP > 0 then
                        local damage = agent.Damage
                        target.hp = math.max(0, target.hp - damage)
                        CreateNotification(agent.Name .. " menyerang " .. target.name .. " sebanyak " .. damage, Color3.fromRGB(50, 200, 50))
                        if target.hp <= 0 then
                            CreateNotification(target.name .. " dikalahkan!", Color3.fromRGB(50, 200, 50))
                            for i = #GameData.RaidEntities, 1, -1 do
                                if GameData.RaidEntities[i] == target then
                                    table.remove(GameData.RaidEntities, i)
                                    break
                                end
                            end
                            if #GameData.RaidEntities == 0 then
                                ShowRaidGUI(GameData.CurrentRaid, false)
                                CreateNotification("Serangan dikalahkan!", Color3.fromRGB(50, 200, 50))
                                GameData.CurrentRaid = nil
                                GameData.TerminatorActive = false
                                GameData.TerminatorAgents = {}
                                CreateNotification("Agen terminator kembali.", Color3.fromRGB(100, 100, 255))
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Loop Serangan Serangan
spawn(function()
    while true do
        wait(2)
        if #GameData.RaidEntities > 0 then
            for _, entity in ipairs(GameData.RaidEntities) do
                if entity.hp > 0 then
                    local damage = entity.dmg
                    if GameData.TerminatorActive and #GameData.TerminatorAgents > 0 then
                        local agent = GameData.TerminatorAgents[math.random(#GameData.TerminatorAgents)]
                        agent.HP = math.max(0, agent.HP - damage)
                        CreateNotification(entity.name .. " menyerang " .. agent.Name .. " sebanyak " .. damage, Color3.fromRGB(200, 50, 50))
                        if agent.HP <= 0 then
                            CreateNotification(agent.Name .. " jatuh!", Color3.fromRGB(200, 50, 50))
                            for i = #GameData.TerminatorAgents, 1, -1 do
                                if GameData.TerminatorAgents[i] == agent then
                                    table.remove(GameData.TerminatorAgents, i)
                                    break
                                end
                            end
                        end
                    else
                        GameData.CosmicShardCoreHealth = math.max(0, GameData.CosmicShardCoreHealth - damage)
                        CreateNotification(entity.name .. " menyerang Inti sebanyak " .. damage, Color3.fromRGB(200, 50, 50))
                        UpdateCoreDisplay()
                        if GameData.CosmicShardCoreHealth <= 0 then
                            CompanyDestroyed()
                            break
                        end
                    end
                end
            end
        end
    end
end)

-- Loop Penurunan Mood Global
spawn(function()
    while true do
        wait(30)
        for _, anomaly in ipairs(GameData.OwnedAnomalies) do
            if not anomaly.IsBreached and not anomaly.Data.NoMoodMeter and not anomaly.Data.NoBreach then
                local decrease = 0
                local class = anomaly.Data.DangerClass
                if class == "X" or class == "XI" then
                    decrease = 5
                elseif class == "XII" or class == "XIII" then
                    decrease = 10
                elseif class == "XIV" then
                    decrease = 15
                end
                if anomaly.Name == "Pangeran Kemasyhuran" then
                    local timeSinceLastBreach = os.time() - GameData.LastGlobalBreachTime
                    if timeSinceLastBreach > 600 then
                        decrease = decrease * 2
                    end
                end
                anomaly.CurrentMood = math.clamp(anomaly.CurrentMood - decrease, 0, 100)
                UpdateRoomDisplay(anomaly)
                if anomaly.CurrentMood <= 0 then
                    if anomaly.Name == "Pangeran Kemasyhuran" then
                        if not anomaly.IsBored then
                            anomaly.IsBored = true
                            anomaly.CurrentMood = 100
                        else
                            TriggerBreach(anomaly, anomaly.RoomFrame)
                        end
                    else
                        if anomaly.Data.IsInanimate then
                            if anomaly.AssignedWorker then
                                anomaly.AssignedWorker.HP = 0
                                GameData.WorkersDied = GameData.WorkersDied + 1
                                CreateNotification(anomaly.Name .. " membunuh pekerja!", Color3.fromRGB(200, 50, 50))
                                anomaly.AssignedWorker = nil
                                anomaly.CurrentMood = anomaly.Data.BaseMood / 2
                                UpdateRoomDisplay(anomaly)
                            end
                        else
                            TriggerBreach(anomaly, anomaly.RoomFrame)
                        end
                    end
                end
            end
        end
    end
end)

function UpdateCoreDisplay()
    local healthPercent = GameData.CosmicShardCoreHealth / GameData.MaxCoreHealth
    
    CoreHealthLabel.Text = string.format("Kesehatan: %d / %d", GameData.CosmicShardCoreHealth, GameData.MaxCoreHealth)
    
    TweenService:Create(CoreHealthBar, TweenInfo.new(0.5), {
        Size = UDim2.new(healthPercent, 0, 1, 0),
        BackgroundColor3 = healthPercent > 0.6 and Color3.fromRGB(100, 200, 255) or healthPercent > 0.3 and Color3.fromRGB(255, 200, 100) or Color3.fromRGB(255, 100, 100)
    }):Play()
    
    CoreStatusLabel.Text = GameData.CosmicShardCoreHealth <= 0 and "STATUS: DIHANCURKAN" or healthPercent < 0.3 and "STATUS: KRITIS" or healthPercent < 0.6 and "STATUS: RUSAK" or "STATUS: DILINDUNGI"
    CoreStatusLabel.TextColor3 = GameData.CosmicShardCoreHealth <= 0 and Color3.fromRGB(255, 50, 50) or healthPercent < 0.3 and Color3.fromRGB(255, 100, 50) or healthPercent < 0.6 and Color3.fromRGB(255, 200, 100) or Color3.fromRGB(100, 255, 100)
    
    UpdateBreachAlert()
end

function UpdateBreachAlert()
    for _, child in pairs(BreachAlertContainer:GetChildren()) do
        child:Destroy()
    end
    
    if #GameData.BreachedAnomalies > 0 then
        local alertLabel = CreateInstance("TextLabel", {
            Name = "BreachAlert",
            Parent = BreachAlertContainer,
            BackgroundColor3 = Color3.fromRGB(150, 20, 20),
            BorderSizePixel = 2,
            BorderColor3 = Color3.fromRGB(255, 50, 50),
            Size = UDim2.new(1, 0, 0, 50),
            Text = string.format("⚠ PELANGGARAN AKTIF: %d ⚠", #GameData.BreachedAnomalies),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        })
        
        CreateInstance("UICorner", {Parent = alertLabel, CornerRadius = UDim.new(0, 8)})
        
        spawn(function()
            while alertLabel.Parent do
                alertLabel.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
                wait(0.5)
                if alertLabel.Parent then
                    alertLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                    wait(0.5)
                end
            end
        end)
    end
end

function CompanyDestroyed()
    local gameOverScreen = CreateInstance("Frame", {
        Name = "GameOverScreen",
        Parent = MainGui,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.3,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 100
    })
    
    local gameOverFrame = CreateInstance("Frame", {
        Name = "GameOverFrame",
        Parent = gameOverScreen,
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 5,
        BorderColor3 = Color3.fromRGB(200, 50, 50),
        Size = isMobile and UDim2.new(0.95, 0, 0.95, 0) or UDim2.new(0, 600, 0, 400),
        Position = isMobile and UDim2.new(0.025, 0, 0.025, 0) or UDim2.new(0.5, -300, 0.5, -200),
        ZIndex = 101
    })
    
    CreateInstance("TextLabel", {
        Parent = gameOverFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 80),
        Position = UDim2.new(0, 0, 0, 50),
        Text = "PERUSAHAAN DIHANCURKAN",
        Font = Enum.Font.GothamBold,
        TextSize = 48,
        TextColor3 = Color3.fromRGB(255, 50, 50),
        ZIndex = 102
    })
    
    CreateInstance("TextLabel", {
        Parent = gameOverFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 0, 100),
        Position = UDim2.new(0, 20, 0, 150),
        Text = "Inti Pecahan Kosmik telah dihancurkan.\nSemua anomali telah kabur.\nPerusahaan Sorchesus telah jatuh.",
        Font = Enum.Font.Gotham,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextWrapped = true,
        ZIndex = 102
    })
    
    CreateInstance("TextLabel", {
        Parent = gameOverFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 0, 60),
        Position = UDim2.new(0, 20, 0, 270),
        Text = string.format("Crucible Akhir: %d\nAnomali Ditahan: %d\nPelanggaran: %d", GameData.Crucible, #GameData.OwnedAnomalies, #GameData.BreachedAnomalies),
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextWrapped = true,
        ZIndex = 102
    })
end

function ShowAnomalyInfo(anomalyInstance)
    local data = anomalyInstance.Data
    local unlocked = anomalyInstance.Unlocked
    local costs = data.Costs

    local infoGui = CreateInstance("Frame", {
        Name = "InfoPopup",
        Parent = MainGui,
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 3,
        BorderColor3 = Color3.fromRGB(100, 100, 100),
        Size = isMobile and UDim2.new(0.95, 0, 0.95, 0) or UDim2.new(0, 500, 0, 400),
        Position = isMobile and UDim2.new(0.025, 0, 0.025, 0) or UDim2.new(0.5, -250, 0.5, -200),
        ZIndex = 10
    })
    
    local title = CreateInstance("TextLabel", {
        Parent = infoGui,
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        Size = UDim2.new(1, 0, 0, 40),
        Text = unlocked.Stat and anomalyInstance.Name or "[Tidak Diklasifikasikan]",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(255, 200, 100)
    })
    
    local contentScroll = CreateInstance("ScrollingFrame", {
        Parent = infoGui,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 1, -100),
        Position = UDim2.new(0, 20, 0, 50),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 6
    })
    
    local contentLayout = CreateInstance("UIListLayout", {
        Parent = contentScroll,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    local function addSection(sectionName, text, isUnlocked, buyFunc, cost)
        if isUnlocked then
            local label = CreateInstance("TextLabel", {
                Parent = contentScroll,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                AutomaticSize = Enum.AutomaticSize.Y
            })
        else
            local btn = CreateInstance("TextButton", {
                Parent = contentScroll,
                BackgroundColor3 = Color3.fromRGB(50, 150, 50),
                Size = UDim2.new(1, 0, 0, 35),
                Text = "Beli " .. sectionName .. " (" .. cost .. " Crucible)",
                Font = Enum.Font.GothamBold,
                TextSize = 16,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            })
            CreateInstance("UICorner", {Parent = btn})
            btn.MouseButton1Click:Connect(function()
                if GameData.Crucible >= cost then
                    UpdateCrucible(-cost)
                    RefreshCrucibleDisplay()
                    buyFunc()
                    infoGui:Destroy()
                    ShowAnomalyInfo(anomalyInstance)
                else
                    CreateNotification("Crucible tidak cukup!", Color3.fromRGB(200, 50, 50))
                end
            end)
        end
        contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
    end
    
    if unlocked.Stat then
        addSection("Deskripsi", "Deskripsi: " .. data.Description, true)
        addSection("Kelas Bahaya", "Kelas Bahaya: " .. data.DangerClass, true)
    else
        addSection("Info Stat", "", false, function() unlocked.Stat = true UpdateRoomDisplay(anomalyInstance) end, costs.Stat)
    end
    
    for _, wt in ipairs({"Pengetahuan", "Sosial", "Berburu", "Pasif"}) do
        if unlocked[wt] then
            local res = data.WorkResults[wt]
            local info = "Info Pekerjaan " .. wt .. ":\nSukses: " .. (res.Success * 100) .. "%\nTidak Sukses: " .. ((1 - res.Success) * 100) .. "%"
            addSection("Info Pekerjaan " .. wt, info, true)
        else
            addSection("Info Pekerjaan " .. wt, "", false, function() unlocked[wt] = true end, costs[wt])
        end
    end
    
    if data.BreachForm then
        if unlocked.BreachForm then
            local bf = data.BreachForm
            local info = "Bentuk Pelanggaran: " .. bf.Name .. "\nKesehatan: " .. bf.Health .. "\nKerusakan M1: " .. bf.M1Damage .. "\nKemampuan: " .. ( #bf.Abilities > 0 and table.concat(bf.Abilities, ", ") or "Tidak Ada" )
            addSection("Bentuk Pelanggaran", info, true)
        else
            addSection("Bentuk Pelanggaran", "", false, function() unlocked.BreachForm = true end, costs.BreachForm)
        end
    end
    
    if costs.Enemies then
        if unlocked.Enemies then
            addSection("Stat Musuh", data.EnemyInfo, true)
        else
            addSection("Stat Musuh", "", false, function() unlocked.Enemies = true end, costs.Enemies)
        end
    end
    
    if data.MXWeapon then
        if unlocked.MXWeapon then
            local mw = data.MXWeapon
            local info = "Senjata MX: " .. mw.Name .. "\nKesempatan mendapatkan: " .. (mw.Chance * 100) .. "%\nLevel: " .. mw.MinLevel .. " hingga " .. mw.MaxLevel .. "\nTipe: Senjata MX\nKerusakan: +" .. mw.Damage
            addSection("Info Senjata MX", info, true)
        else
            addSection("Info Senjata MX", "", false, function() unlocked.MXWeapon = true end, costs.MXWeapon)
        end
    end
    
    if data.MXArmor then
        if unlocked.MXArmor then
            local ma = data.MXArmor
            local info = "Armor MX: " .. ma.Name .. "\nKesempatan mendapatkan: " .. (ma.Chance * 100) .. "%\nLevel: " .. ma.MinLevel .. " hingga " .. ma.MaxLevel .. "\nTipe: Armor MX\nKesehatan: +" .. ma.Health
            addSection("Info Armor MX", info, true)
        else
            addSection("Info Armor MX", "", false, function() unlocked.MXArmor = true end, costs.MXArmor)
        end
    end
    
    if data.ManagementTips then
        for i, tip in ipairs(data.ManagementTips) do
            if unlocked.Management[i] then
                addSection("Tips Manajemen " .. i, "Tips Manajemen " .. i .. ": " .. tip, true)
            else
                addSection("Tips Manajemen " .. i, "", false, function() unlocked.Management[i] = true end, costs.Management[i])
            end
        end
    end
    
    local closeBtn = CreateInstance("TextButton", {
        Parent = infoGui,
        BackgroundColor3 = Color3.fromRGB(100, 100, 100),
        Size = UDim2.new(0, 100, 0, 35),
        Position = UDim2.new(0.5, -50, 1, -50),
        Text = "Tutup",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    CreateInstance("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0, 6)})
    
    closeBtn.MouseButton1Click:Connect(function()
        infoGui:Destroy()
    end)
end

function CreateNotification(message, color)
    local notif = CreateInstance("Frame", {
        Name = "Notification",
        Parent = MainGui,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 400, 0, 60),
        Position = UDim2.new(0.5, -200, 0, -70)
    })
    CreateInstance("UICorner", {Parent = notif, CornerRadius = UDim.new(0, 10)})
    
    CreateInstance("TextLabel", {
        Parent = notif,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = message,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextWrapped = true
    })
    
    TweenService:Create(notif, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -200, 0, 10)}):Play()
    
    wait(3)
    TweenService:Create(notif, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -200, 0, -70)}):Play()
    wait(0.3)
    notif:Destroy()
end

-- Sistem Kereta Putih
local function GenerateRandomDocuments()
    local anomalyNames = {}
    for name, _ in pairs(AnomalyDatabase) do
        table.insert(anomalyNames, name)
    end
    
    local documents = {}
    for i = 1, 3 do
        local randomIndex = math.random(1, #anomalyNames)
        documents[i] = anomalyNames[randomIndex]
    end
    
    return documents
end

local function StartWhiteTrain()
    GameData.WhiteTrainActive = true
    GameData.TrainTimer = 720
    
    TrainStatus.Text = "Kereta Putih Telah Datang!"
    TrainStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
    BuyDocButton.Visible = true
    TrainTimer.Visible = true
    
    CreateNotification("Kereta Putih telah datang!", Color3.fromRGB(100, 100, 200))
    
    spawn(function()
        while GameData.TrainTimer > 0 and GameData.WhiteTrainActive do
            local minutes = math.floor(GameData.TrainTimer / 60)
            local seconds = GameData.TrainTimer % 60
            TrainTimer.Text = string.format("Kereta pergi dalam %02d:%02d", minutes, seconds)
            wait(1)
            GameData.TrainTimer = GameData.TrainTimer - 1
        end
        
        if GameData.WhiteTrainActive then
            EndWhiteTrain()
        end
    end)
end

local function EndWhiteTrain()
    GameData.WhiteTrainActive = false
    
    TrainStatus.Text = "Kereta Putih telah pergi..."
    TrainStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
    BuyDocButton.Visible = false
    TrainTimer.Visible = false
    DocumentGui.Visible = false
    
    CreateNotification("Kereta Putih telah berangkat.", Color3.fromRGB(100, 100, 100))
    
    spawn(function()
        GameData.TrainTimer = 1200
        while GameData.TrainTimer > 0 do
            local minutes = math.floor(GameData.TrainTimer / 60)
            local seconds = GameData.TrainTimer % 60
            TrainStatus.Text = string.format("Datang dalam %02d:%02d", minutes, seconds)
            wait(1)
            GameData.TrainTimer = GameData.TrainTimer - 1
        end
        StartWhiteTrain()
    end)
end

-- Fungsi Serangan
local function StartRaid(sphere)
    local raids = RaidDatabase[sphere]
    if not raids or #raids == 0 then return end
    local picked = raids[math.random(1, #raids)]
    GameData.CurrentRaid = picked
    GameData.CurrentRaid.sphere = sphere
    GameData.RaidEntities = {}
    for _, ano in ipairs(picked.anomalies) do
        for i = 1, ano.count do
            table.insert(GameData.RaidEntities, {name = ano.name, hp = ano.hp, maxHp = ano.hp, dmg = ano.dmg})
        end
    end
    ShowRaidGUI(picked, true)
    CreateNotification("Serangan " .. sphere .. " Dimulai: " .. picked.name, picked.color)
end

local function ShowRaidGUI(raid, isStart)
    local gui = CreateInstance("Frame", {
        Parent = MainGui,
        BackgroundColor3 = raid.color,
        Size = UDim2.new(0.5, 0, 0.2, 0),
        Position = UDim2.new(1.5, 0, 0.4, 0),
        ZIndex = 20
    })
    CreateInstance("UICorner", {Parent = gui})
    local topText = CreateInstance("TextLabel", {
        Parent = gui,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0.3, 0),
        Text = raid.name .. " " .. raid.sphere,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    local mainText = CreateInstance("TextLabel", {
        Parent = gui,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0.7, 0),
        Position = UDim2.new(0, 0, 0.3, 0),
        Text = isStart and raid.quote or raid.lostQuote,
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextWrapped = true
    })
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(gui, tweenInfo, {Position = UDim2.new(0.25, 0, 0.4, 0)}):Play()
    wait(5)
    tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    TweenService:Create(gui, tweenInfo, {Position = UDim2.new(-0.5, 0, 0.4, 0)}):Play()
    wait(0.5)
    gui:Destroy()
end

-- Fungsi Protokol Terminator
local function IsTerminatorAvailable()
    if #GameData.BreachedAnomalies >= 5 then
        return true
    end
    for _, breach in ipairs(GameData.BreachedAnomalies) do
        if breach.Instance.Data.DangerClass == "XIV" then
            return true
        end
    end
    return false
end

local function ShowEndDayScreen()
    local endScreen = CreateInstance("Frame", {
        Name = "EndDayScreen",
        Parent = MainGui,
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1,0,1,0),
        ZIndex = 50
    })

    local mobileFrame = CreateInstance("Frame", {
        Parent = endScreen,
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BorderSizePixel = 5,
        BorderColor3 = Color3.fromRGB(255,0,0),
        Size = UDim2.new(0.4,0,0.6,0),
        Position = UDim2.new(0.3,0,0.2,0),
        ZIndex = 51
    })

    local scoresLayout = CreateInstance("UIListLayout", {
        Parent = mobileFrame,
        Padding = UDim.new(0,10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center
    })

    local function addScore(text)
        CreateInstance("TextLabel", {
            Parent = mobileFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,30),
            Text = text,
            Font = Enum.Font.GothamBold,
            TextSize = 18,
            TextColor3 = Color3.fromRGB(255,255,255)
        })
    end

    addScore("Hari: " .. GameData.CurrentDay)
    addScore("Anomali Melanggar: " .. GameData.TotalBreaches)
    addScore("Pekerja Mati: " .. GameData.WorkersDied)
    addScore("Penjaga Mati: " .. GameData.GuardsDied)
    addScore("Uang: " .. GameData.Crucible)

    local continueBtn = CreateInstance("TextButton", {
        Parent = mobileFrame,
        BackgroundColor3 = Color3.fromRGB(50,150,50),
        Size = UDim2.new(0.8,0,0,50),
        Text = "Lanjut ke Hari Selanjutnya",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = Color3.fromRGB(255,255,255)
    })
    CreateInstance("UICorner", {Parent = continueBtn})

    continueBtn.MouseButton1Click:Connect(function()
        GameData.CurrentDay = GameData.CurrentDay + 1
        GameData.DailyCrucible = 0
        GameData.AnomaliesAcceptedToday = 0
        GameData.DocumentsPurchasedToday = false
        DayLabel.Text = "Hari: " .. GameData.CurrentDay
        UpdateQuotaDisplay()
        endScreen:Destroy()
        local raidDays = {[5] = "Troposphere", [10] = "Stratosphere", [25] = "Mesosphere", [50] = "Thermosphere", [75] = "Exosphere"}
        local sphere = raidDays[GameData.CurrentDay]
        if sphere and RaidDatabase[sphere] and #RaidDatabase[sphere] > 0 then
            StartRaid(sphere)
        end
    end)
end

-- Koneksi Tombol
EmployeeButton.MouseButton1Click:Connect(function()
    EmployeeShop.Visible = true
end)

CloseShopButton.MouseButton1Click:Connect(function()
    EmployeeShop.Visible = false
end)

OuterGuardButton.MouseButton1Click:Connect(function()
    PopulateOuterGui()
    OuterGuardGui.Visible = true
end)

CloseOuterButton.MouseButton1Click:Connect(function()
    OuterGuardGui.Visible = false
end)

CloseOuterBottom.MouseButton1Click:Connect(function()
    OuterGuardGui.Visible = false
end)

TerminatorButton.MouseButton1Click:Connect(function()
    if not IsTerminatorAvailable() then
        CreateNotification("Protokol Terminator tidak tersedia!", Color3.fromRGB(200, 50, 50))
        return
    end
    if GameData.Crucible < 35000 then
        CreateNotification("Crucible tidak cukup!", Color3.fromRGB(200, 50, 50))
        return
    end
    UpdateCrucible(-35000)
    RefreshCrucibleDisplay()
    
    local agents = {
        {Name = "Agen Aisyah", HP = 3500, Damage = 500},
        {Name = "Agen Blake", HP = 4000, Damage = 350},
        {Name = "Agen Tyler", HP = 3750, Damage = 450},
        {Name = "Agen Toby", HP = 3000, Damage = 750},
        {Name = "Agen Anastasia", HP = 4300, Damage = 530},
        {Name = "Agen Elmer", HP = 6000, Damage = 600},
        {Name = "Juggernaut Paul", HP = 9000, Damage = 1000},
        {Name = "Juggernaut Dexter", HP = 10000, Damage = 1500},
        {Name = "Komandan Britney", HP = 17500, Damage = 3000}
    }
    
    GameData.TerminatorAgents = agents
    GameData.TerminatorActive = true
    CreateNotification("Protokol Terminator diaktifkan!", Color3.fromRGB(255, 0, 0))
end)

InventoryButton.MouseButton1Click:Connect(function()
    PopulateInventory()
    InventoryGui.Visible = true
end)

CloseInvButton.MouseButton1Click:Connect(function()
    InventoryGui.Visible = false
end)

CloseWGButton.MouseButton1Click:Connect(function()
    AssignGui.Visible = false
end)

CloseAssignButtonBottom.MouseButton1Click:Connect(function()
    AssignGui.Visible = false
end)

BuyDocButton.MouseButton1Click:Connect(function()
    if GameData.DocumentsPurchasedToday then
        CreateNotification("Sudah dibeli hari ini!", Color3.fromRGB(200, 50, 50))
        return
    end
    if GameData.Crucible >= 100 then
        UpdateCrucible(-100)
        RefreshCrucibleDisplay()
        
        GameData.CurrentDocuments = GenerateRandomDocuments()
        DocumentGui.Visible = true
        AnomalyInfo.Visible = false
        GameData.DocumentsPurchasedToday = true
        
        CreateNotification("Dokumen dibeli!", Color3.fromRGB(100, 200, 100))
    else
        CreateNotification("Crucible tidak cukup!", Color3.fromRGB(200, 50, 50))
    end
end)

for i = 1, 3 do
    local docBtn = DocContainer:FindFirstChild("Document" .. i)
    docBtn.MouseButton1Click:Connect(function()
        local selectedAnomaly = GameData.CurrentDocuments[i]
        if selectedAnomaly then
            local anomalyData = AnomalyDatabase[selectedAnomaly]
            
            AnomalyInfo.Visible = true
            AnomalyNameLabel.Text = "???"
            DangerClassLabel.Text = "Kelas Bahaya: ???"
            DescriptionLabel.Text = anomalyData.Description
            
            GameData.SelectedDocument = selectedAnomaly
            
            for j = 1, 3 do
                local btn = DocContainer:FindFirstChild("Document" .. j)
                btn.BorderColor3 = j == i and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(100, 100, 120)
                btn.BorderSizePixel = j == i and 3 or 2
            end
        end
    end)
end

AcceptButton.MouseButton1Click:Connect(function()
    if GameData.SelectedDocument then
        if GameData.AnomaliesAcceptedToday >= 1 then
            CreateNotification("Hanya 1 anomali per hari!", Color3.fromRGB(200, 50, 50))
            return
        end
        CreateAnomalyRoom(GameData.SelectedDocument)
        GameData.AnomaliesAcceptedToday = GameData.AnomaliesAcceptedToday + 1
        CreateNotification("Anomali diterima: " .. GameData.SelectedDocument, Color3.fromRGB(50, 200, 50))
        DocumentGui.Visible = false
        AnomalyInfo.Visible = false
        GameData.SelectedDocument = nil
    end
end)

DeclineButton.MouseButton1Click:Connect(function()
    AnomalyInfo.Visible = false
    GameData.SelectedDocument = nil
    
    for i = 1, 3 do
        local btn = DocContainer:FindFirstChild("Document" .. i)
        btn.BorderColor3 = Color3.fromRGB(100, 100, 120)
        btn.BorderSizePixel = 2
    end
end)

CloseDocButton.MouseButton1Click:Connect(function()
    DocumentGui.Visible = false
    AnomalyInfo.Visible = false
    GameData.SelectedDocument = nil
end)

RerollButton.MouseButton1Click:Connect(function()
    if GameData.Crucible >= 100 then
        UpdateCrucible(-100)
        RefreshCrucibleDisplay()
        GameData.CurrentDocuments = GenerateRandomDocuments()
        AnomalyInfo.Visible = false
        GameData.SelectedDocument = nil
        for i=1,3 do
            local btn = DocContainer:FindFirstChild("Document" .. i)
            btn.BorderSizePixel = 2
            btn.BorderColor3 = Color3.fromRGB(100,100,120)
        end
        CreateNotification("Dokumen di-reroll!", Color3.fromRGB(100,200,100))
    else
        CreateNotification("Crucible tidak cukup!", Color3.fromRGB(200,50,50))
    end
end)

EndDayButton.MouseButton1Click:Connect(function()
    local quota = GameData.CurrentDay <= #Quotas and Quotas[GameData.CurrentDay] or Quotas[#Quotas]
    if GameData.DailyCrucible < quota then
        CreateNotification("Kuota tidak tercapai!", Color3.fromRGB(200,50,50))
        return
    end
    ShowEndDayScreen()
end)

-- Inisialisasi Game
wait(0.5)
CreateNotification("Selamat datang di Perusahaan Sorchesus!", Color3.fromRGB(200, 50, 50))
wait(2)

wait(3)
StartWhiteTrain()

UpdateQuotaDisplay()

print("GUI Perusahaan Sorchesus Dimuat Berhasil!")
