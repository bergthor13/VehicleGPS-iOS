//
//  File.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 01/04/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation

struct Strings {
    static let save = NSLocalizedString("Vista", comment: "Used when saving something")
    static let cancel = NSLocalizedString("Hætta við", comment: "Used when canceling something")
    static let delete = NSLocalizedString("Eyða", comment: "Used when canceling something")
    static let edit = NSLocalizedString("Breyta", comment: "")

    static let day = NSLocalizedString("Dagur", comment: "")
    static let month = NSLocalizedString("Mánuður", comment: "")
    static let year = NSLocalizedString("Ár", comment: "")
    
    struct colors {
        static let red = NSLocalizedString("Rauður", comment: "Name for the color red")
        static let green = NSLocalizedString("Grænn", comment: "Name for the color green")
        static let black = NSLocalizedString("Svartur", comment: "Name for the color black")
        static let blue = NSLocalizedString("Blár", comment: "Name for the color blue")
        static let brown = NSLocalizedString("Brúnn", comment: "Name for the color brown")
        static let darkGray = NSLocalizedString("Dökkgrár", comment: "Name for the color dark gray")
        static let white = NSLocalizedString("Hvítur", comment: "Name for the color white")
        static let orange = NSLocalizedString("Appelsínugulur", comment: "Name for the color orange")
    }
    
    struct titles {
        static let logs = NSLocalizedString("Ferlar", comment: "Logs Title")
        static let history = NSLocalizedString("Saga", comment: "History Title")
        static let journeys = NSLocalizedString("Ferðalög", comment: "Journeys Title")
        static let vehicles = NSLocalizedString("Farartæki", comment: "Vehicles Title")
        static let settings = NSLocalizedString("Stillingar", comment: "Settings Title")
        static let database = NSLocalizedString("Gagnagrunnur", comment: "Database Title")
        static let vgpsDevice = NSLocalizedString("VehicleGPS tæki", comment: "")

        static let importFile = NSLocalizedString("Flytja inn skrá", comment: "")
        
        static let newVehicle = NSLocalizedString("Nýtt farartæki", comment: "")
        static let newJourney = NSLocalizedString("Nýtt ferðalag", comment: "")
        
        
    }
    
    struct settings {
        static let general = NSLocalizedString("Almennt", comment: "")
        static let connectToVGPS = NSLocalizedString("Tengjast við VehicleGPS", comment: "")
        static let objects = NSLocalizedString("Hlutir", comment: "")
        static let files = NSLocalizedString("Skrár", comment: "")
        static let logFiles = NSLocalizedString("Ferlaskrár", comment: "")
        static let previewImages = NSLocalizedString("Yfirlitsmyndir", comment: "")
        static let databaseMaintenance = NSLocalizedString("Framkvæma gagnagrunnsviðhald", comment: "")
    }
    
    static let editVehicle = NSLocalizedString("Breyta farartæki", comment: "")

    static let noLogs = NSLocalizedString("Engir ferlar", comment: "")
    static let noHistory = NSLocalizedString("Engin saga", comment: "")
    static let noJourneys = NSLocalizedString("Engin ferðalög", comment: "")
    static let noVehicles = NSLocalizedString("Engin farartæki", comment: "")


    static let map = NSLocalizedString("Kort", comment: "")
    static let statistics = NSLocalizedString("Tölfræði", comment: "")
    
    static let summary = NSLocalizedString("Samantekt", comment: "")
    static let startTime = NSLocalizedString("Byrjunartími", comment: "")
    static let endtime = NSLocalizedString("Endatími", comment: "")
    static let distance = NSLocalizedString("Vegalengd", comment: "")
    static let duration = NSLocalizedString("Tímalengd", comment: "")
    static let datapoints = NSLocalizedString("Gagnapunktar", comment: "")
    static let averageSpeed = NSLocalizedString("Meðalhraði", comment: "")
    static let setAsDefault = NSLocalizedString("Setja sem sjálfgefið", comment: "")

    static let shareCSV = NSLocalizedString("Deila CSV skrá", comment: "")
    static let shareGPX = NSLocalizedString("Deila GPX skrá", comment: "")
    static let processAgain = NSLocalizedString("Vinna úr skránni aftur", comment: "")
    static let splitLog = NSLocalizedString("Skipta ferli í tvennt", comment: "")

    static let speed = NSLocalizedString("Hraði", comment: "")
    static let elevation = NSLocalizedString("Hæð yfir sjávarmáli", comment: "")
    static let hAcc = NSLocalizedString("Lárétt nákvæmni", comment: "")
    static let pdop = NSLocalizedString("PDOP", comment: "")
    static let rpm = NSLocalizedString("Snúningar á mínútu", comment: "")
    static let engineLoad = NSLocalizedString("Álag vélar", comment: "")
    static let throttlePos = NSLocalizedString("Eldsneytisgjöf", comment: "")
    static let coolTemp = NSLocalizedString("Hiti á kælivökva", comment: "")
    static let ambTemp = NSLocalizedString("Útihiti", comment: "")
    static let heartRate = NSLocalizedString("Púls", comment: "")
    static let cadence = NSLocalizedString("Taktur", comment: "")
    static let power = NSLocalizedString("Afl", comment: "")

    static let parse = NSLocalizedString("Þátta", comment: "")

    static let selectColor = NSLocalizedString("Velja lit", comment: "")

    static let parsingLeftPlural = NSLocalizedString("Þátta. %i ferlar eftir.", comment: "")
    
    static let newLogSingular = NSLocalizedString("%i nýr ferill í boði", comment: "")
    static let newLogPlural = NSLocalizedString("%i nýjir ferlar í boði", comment: "")


    static let downloadingLeft = NSLocalizedString("Hleður niður. %i ferlar eftir.", comment: "")
    static let connectedTo = NSLocalizedString("Tengt við %@", comment: "")

    static let noVehicle = NSLocalizedString("Ekkert farartæki", comment: "")

    static let logs = NSLocalizedString("ferlar", comment: "")
    static let selectVehicle = NSLocalizedString("Velja farartæki", comment: "")
    static let share = NSLocalizedString("Deila", comment: "")
    static let importFile = NSLocalizedString("Flytja inn", comment: "")
    
    static let downloadComplete = NSLocalizedString("Niðurhali lokið.", comment: "")
    static let noNewLogs = NSLocalizedString("Engir nýir ferlar í boði", comment: "")
    
    static let ok = NSLocalizedString("Í lagi", comment: "")
    
    static let authorizationError = NSLocalizedString("Villa í auðkenningu", comment: "")
    static let sftpConnError = NSLocalizedString("Villa í tengingu við SFTP vefþjón", comment: "")

    static let readingFile = NSLocalizedString("Les skrá...", comment: "")
    static let parsingLines = NSLocalizedString("Þáttar línur", comment: "")
    
    static let noTrack = NSLocalizedString("Enginn ferill", comment: "")
    static let noStartTime = NSLocalizedString("Enginn byrjunartími", comment: "")

    
    static let takePicture = NSLocalizedString("Taka mynd", comment: "")
    static let photoLibrary = NSLocalizedString("Myndasafn", comment: "")
    static let searchForLogs = NSLocalizedString("Leita að nýjum ferlum", comment: "")
    static let exportMapAsImage = NSLocalizedString("Flytja kort út sem mynd", comment: "")
        
    static let dummyIdentifier = "dummy"
}
