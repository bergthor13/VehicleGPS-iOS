import Foundation

extension Double {
    func asDistanceString(with decimalCount: Int?=2) -> String {
        let formatter = VGDistanceFormatter()
        formatter.numberFormatter.maximumFractionDigits = decimalCount!
        formatter.numberFormatter.minimumFractionDigits = decimalCount!
        return formatter.string(fromMeters: self)
    }
    
    func asDurationString() -> String {
        let formatter = VGDurationFormatter()
        return formatter.string(from: self)!
    }
}

