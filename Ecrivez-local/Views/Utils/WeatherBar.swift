import SwiftUI

struct WeatherBar: View {
    var weather: String
    
    var body: some View {
        HStack {
            Image(systemName: weatherIcon)
                .foregroundColor(.white)
                .font(.title)
            Text(weather)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(5)
        .background(
            LinearGradient(gradient: Gradient(colors: backgroundGradient), startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(40)
        .padding()
    }
    
    private var weatherIcon: String {
        switch weather {
        case "Sunny":
            return "sun.max.fill"
        case "Cloudy":
            return "cloud"
        case "Partly Cloudy":
            return "cloud.sun"
        case "Rainy":
            return "cloud.rain.fill"
        case "Stormy":
            return "cloud.bolt.fill"
        case "Snowy":
            return "snow"
        default:
            return "questionmark"
        }
    }
    
    private var backgroundGradient: [Color] {
        switch weather {
        case "Sunny":
            return [Color.blue, Color.orange]
        case "Cloudy":
            return [Color.black.opacity(0.2), Color.gray]
        case "Rainy":
            return [Color.gray.opacity(0.6), Color.blue.opacity(0.6)]
        case "Stormy":
            return [Color.black.opacity(0.8), Color.gray]
        case "Snowy":
            return [Color.blue.opacity(0.3), Color.gray.opacity(0.2)]
        default:
            return [Color.black.opacity(0.2), Color.gray]
        }
    }
}

#Preview {
    WeatherBar(weather: "Cloudy")
}
