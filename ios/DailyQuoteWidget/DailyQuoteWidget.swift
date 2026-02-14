//
//  DailyQuoteWidget.swift
//  DailyQuoteWidget
//
//  Created by Muhammad Awais on 16/10/2025.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: "Your daily inspiration", author: "Anonymous")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> ()) {
        let entry = QuoteEntry(date: Date(), quote: "Stay focused and never give up", author: "Muhammad Awais")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [QuoteEntry] = []
        
        let quotes = [
            ("The only way to do great work is to love what you do.", "Steve Jobs"),
            ("Success is not final, failure is not fatal.", "Winston Churchill"),
            ("Believe you can and you're halfway there.", "Theodore Roosevelt")
        ]
        
        let currentDate = Date()
        for hourOffset in 0 ..< 3 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let quote = quotes[hourOffset % quotes.count]
            let entry = QuoteEntry(date: entryDate, quote: quote.0, author: quote.1)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: String
    let author: String
}

// MARK: - Blur Background Component
struct BlurView: View {
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Frosted glass effect
            Color.white.opacity(0.1)
        }
        .background(.ultraThinMaterial)
    }
}

struct DailyQuoteWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        ZStack {
            // Blur background layer
            BlurView()
            
            // Responsive content based on widget size
            switch widgetFamily {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            case .accessoryCircular:
                AccessoryCircularView(entry: entry)
            case .accessoryRectangular:
                AccessoryRectangularView(entry: entry)
            case .accessoryInline:
                AccessoryInlineView(entry: entry)
            @unknown default:
                SmallWidgetView(entry: entry)
            }
        }
    }
}

// MARK: - Small Widget (Responsive & Optimized)
struct SmallWidgetView: View {
    let entry: QuoteEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Added header for context
           
            
            // Quote text - responsive sizing with proper wrapping
            Text(entry.quote)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(4)  // Reduced from 5 to make room for header
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Spacer()
            
            // Author
            Text("— \(entry.author)")
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.black.opacity(0.8))
                .lineLimit(1)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .padding(16)
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: QuoteEntry
    
    var body: some View {
        HStack(spacing: 16) {
        
            // Right side - Content
            VStack(alignment: .leading, spacing: 8) {
                // Author name
                Text(entry.author)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text(entry.quote)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Spacer()
            }
            
            Spacer()
        }
        .padding(20)
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: QuoteEntry
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                
                
                Text(entry.author)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                Text(entry.date, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            
            Spacer()
            
            // Quote
            VStack(spacing: 16) {
                Text(entry.quote)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                
                // Decorative divider
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.5), .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 2)
                    .frame(maxWidth: 200)
            }
            
            Spacer()
        }
        .padding(24)
    }
}

// MARK: - Lock Screen Widgets
struct AccessoryCircularView: View {
    let entry: QuoteEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
             
                Text("Quote")
                    .font(.system(size: 10))
            }
        }
    }
}

struct AccessoryRectangularView: View {
    let entry: QuoteEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
              
                Text(entry.author)
                    .font(.headline)
            }
            Text(entry.quote)
                .font(.caption)
                .lineLimit(2)
        }
    }
}

struct AccessoryInlineView: View {
    let entry: QuoteEntry
    
    var body: some View {
        Text("\(entry.quote)")
            .lineLimit(1)
    }
}

// MARK: - Widget Configuration
struct DailyQuoteWidget: Widget {
    let kind: String = "DailyQuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DailyQuoteWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Daily Quote")
        .description("Get inspired with daily motivational quotes.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    DailyQuoteWidget()
} timeline: {
    QuoteEntry(date: .now, quote: "The only way to do great work is to love what you do.", author: "Steve Jobs")
    QuoteEntry(date: .now, quote: "Success is not final, failure is not fatal.", author: "Winston Churchill")
}

#Preview(as: .systemMedium) {
    DailyQuoteWidget()
} timeline: {
    QuoteEntry(date: .now, quote: "Believe you can and you're halfway there.", author: "Theodore Roosevelt")
}

#Preview(as: .systemLarge) {
    DailyQuoteWidget()
} timeline: {
    QuoteEntry(date: .now, quote: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt")
}
