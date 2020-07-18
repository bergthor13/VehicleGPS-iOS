import Foundation

class LogDateSplitter {
    static func splitLogsByDate(trackList:[VGTrack]) -> ([String], [String: [VGTrack]]){
        var result = Dictionary<String, [VGTrack]>()
        var sectionKeys = [String]()
        for track in trackList {
            var day = ""
            if let timeStart = track.timeStart {
                day = String(String(describing: timeStart).prefix(10))
            } else {
                day = String(track.fileName.prefix(10))
            }
            
            if result[day] == nil {
                result[day] = [VGTrack]()
            }
            if !sectionKeys.contains(day) {
                sectionKeys.append(day)
            }
            result[day]!.append(track)
        }
        
        // Reorder the sections and lists to display the newest log first.
        sectionKeys = sectionKeys.sorted().reversed()
        
        for (day, list) in result {
            result[day] = list.sorted { (first, second) -> Bool in
                if first.timeStart != nil && second.timeStart != nil {
                    return first.timeStart! > second.timeStart!
                }
                return first.fileName > second.fileName
            }
        }
        
        return (sectionKeys, result)
    }


}
