//
//  NotificationMessageProvider.swift
//  Write-It-Down
//
//  Created by Claude on 1/29/25.
//

import Foundation

/// Intelligent message provider for daily writing reminder notifications
/// 
/// **Core Philosophy**: Varied, contextual messages maintain user engagement over time
/// **Psychology Insight**: Repetitive notifications lead to habituation and ignored reminders
/// **Solution**: Smart rotation based on time, day, and user patterns
/// 
/// **Engineering Decisions:**
/// 1. **Message Categories**: Different tones for different contexts and user preferences
/// 2. **Time-Based Selection**: Evening messages focus on reflection, morning on inspiration
/// 3. **Deterministic Rotation**: Uses date-based seeding to ensure variety without randomness
/// 4. **Extensible Design**: Easy to add new categories and messages for A/B testing
final class NotificationMessageProvider {
    
    // MARK: - Message Categories
    
    /// **Reflective Messages**: Perfect for evening reminders (6 PM - 10 PM)
    /// **Tone**: Contemplative, encouraging daily reflection and processing
    /// **Psychology**: Taps into natural end-of-day reflection patterns
    /// **User Research**: People naturally reflect more in evenings vs. mornings
    private let reflectiveMessages = [
        "Ready to reflect on your day?",           // **Classic**: Simple, direct invitation
        "How did your day go?",                    // **Conversational**: Feels like a friend asking
        "A moment for reflection...",              // **Gentle**: Low-pressure, meditative tone
        "Time to capture today's thoughts",        // **Action-oriented**: Emphasizes capturing vs. creating
        "What stood out about today?",             // **Specific**: Helps users focus on memorable moments
        "Ready to process today's experiences?"    // **Therapeutic**: Appeals to mental health benefits
    ]
    
    /// **Inspirational Messages**: Great for morning/afternoon reminders
    /// **Tone**: Energetic, forward-looking, creativity-focused
    /// **Psychology**: Aligns with natural creativity peaks and goal-oriented thinking
    /// **Timing Strategy**: Works best when users have mental energy for creative thinking
    private let inspirationalMessages = [
        "Any new inspiration to capture?",         // **Creative**: Targets artistic/creative users
        "What sparked your creativity today?",     // **Past-focused**: Helps capture fleeting ideas
        "Ready to turn ideas into words?",         // **Action**: Motivates transition from thinking to writing
        "Time to inspire your future self",        // **Future-focused**: Long-term motivation
        "What brilliant thoughts are brewing?",    // **Playful**: Light, encouraging tone
        "Ready to create something meaningful?"    // **Purpose**: Appeals to users seeking significance
    ]
    
    /// **Casual Messages**: Perfect for any time, especially weekends
    /// **Tone**: Friendly, low-pressure, approachable
    /// **Strategy**: Reduces writing anxiety by making it feel effortless
    /// **User Type**: Appeals to users who find formal prompts intimidating
    private let casualMessages = [
        "What's new?",                            // **Ultra-simple**: Lowest barrier to entry
        "Anything worth remembering?",            // **Memory-focused**: Emphasizes preservation vs. creation
        "Quick check-in time!",                   // **Brief**: Suggests short, easy writing session
        "What's on your mind?",                   // **Open-ended**: No pressure for specific content
        "Care to jot down a quick thought?",      // **Minimal commitment**: Just a "quick thought"
        "Ready for a brain dump?"                 // **Colloquial**: Appeals to younger users
    ]
    
    /// **Achievement Messages**: Best for end-of-week or after user hasn't written recently
    /// **Tone**: Positive, accomplishment-focused, encourages progress documentation
    /// **Psychology**: Leverages pride and progress motivation
    /// **Timing**: Most effective after successful days or when building momentum
    private let achievementMessages = [
        "Ready to document today's wins?",        // **Victory-focused**: Emphasizes positive events
        "What went well today?",                  // **Gratitude**: Promotes positive mental patterns
        "Time to celebrate your progress",        // **Self-celebration**: Encourages recognition of growth
        "Capture today's victories, big or small", // **Inclusive**: All victories count, reduces pressure
        "What are you proud of today?",           // **Pride**: Direct appeal to accomplishment feelings
        "Document your journey forward"           // **Journey**: Long-term perspective on growth
    ]
    
    // MARK: - Smart Message Selection
    
    /// Selects the most appropriate message based on time and context
    /// **Algorithm Design**: Multi-factor selection for personalized experience
    /// 
    /// **Selection Factors**:
    /// 1. **Time of Day**: Different tones work better at different hours
    /// 2. **Day of Week**: Weekends get more casual, weekdays more structured
    /// 3. **Deterministic Rotation**: Consistent experience while avoiding repetition
    /// 
    /// - Parameter reminderTime: The scheduled time for the reminder
    /// - Returns: Contextually appropriate message string
    func getDailyReminderMessage(for reminderTime: Date) -> String {
        
        // **Calendar Setup**: Use current calendar for proper locale/timezone handling
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let weekday = calendar.component(.weekday, from: Date()) // **Current day**: For weekend detection
        
        // **Weekend Detection**: Sunday = 1, Saturday = 7 in iOS Calendar
        let isWeekend = weekday == 1 || weekday == 7
        
        // **Time-Based Category Selection**
        /// **Algorithm Explanation**:
        /// - **6-11 AM**: Inspirational (morning energy, goal-setting time)
        /// - **12-5 PM**: Mixed casual/inspirational (midday flexibility)  
        /// - **6-10 PM**: Reflective (natural reflection time)
        /// - **11 PM-5 AM**: Casual (late night, low pressure)
        let selectedCategory: [String]
        
        switch hour {
        case 6...11:
            // **Morning Strategy**: Capitalize on fresh mental energy
            selectedCategory = isWeekend ? casualMessages : inspirationalMessages
            
        case 12...17:
            // **Afternoon Strategy**: Flexible approach based on day type
            selectedCategory = isWeekend ? casualMessages : 
                               (hour < 15 ? inspirationalMessages : reflectiveMessages)
            
        case 18...22:
            // **Evening Strategy**: Perfect time for reflection and processing
            selectedCategory = reflectiveMessages
            
        default:
            // **Late Night/Early Morning**: Keep it simple and pressure-free
            selectedCategory = casualMessages
        }
        
        // **Deterministic Selection Algorithm**
        /// **Why Not Random**: Random selection can repeat messages frequently
        /// **Deterministic Benefits**: 
        /// - Users get varied messages without immediate repeats
        /// - Predictable rotation helps users anticipate favorite messages
        /// - Easier to debug and test specific message scenarios
        /// 
        /// **Algorithm**: Uses day of year as seed for selection
        /// **Rotation Period**: Messages repeat every N days (where N = category size)
        /// **Distribution**: Ensures even distribution across all messages in category
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let messageIndex = (dayOfYear - 1) % selectedCategory.count
        let selectedMessage = selectedCategory[messageIndex]
        
        // **Development Logging**: Helps understand message selection in testing
        /// **Production Note**: Consider removing or reducing logging level for app store
        #if DEBUG
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        print("📝 NotificationMessageProvider:")
        print("   Time: \(formatter.string(from: reminderTime)) (hour: \(hour))")
        print("   Weekend: \(isWeekend)")
        print("   Category: \(categoryName(for: selectedCategory))")
        print("   Selected: \"\(selectedMessage)\"")
        #endif
        
        return selectedMessage
    }
    
    // MARK: - Testing & Development Support
    
    /// Gets a message from a specific category (useful for testing)
    /// **Development Tool**: Allows testing specific message types
    /// **Future Use**: Could enable user preference for message style
    /// 
    /// - Parameter category: The desired message category
    /// - Parameter index: Specific message index (nil for rotation-based selection)
    /// - Returns: Message from the specified category
    func getMessage(from category: MessageCategory, at index: Int? = nil) -> String {
        let messages = getMessages(for: category)
        
        if let specificIndex = index, specificIndex < messages.count {
            return messages[specificIndex]
        }
        
        // **Fallback**: Use same deterministic selection as main algorithm
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let messageIndex = (dayOfYear - 1) % messages.count
        return messages[messageIndex]
    }
    
    /// Gets all messages from a specific category
    /// **Use Cases**: Settings UI, A/B testing, message preview
    func getAllMessages() -> [MessageCategory: [String]] {
        return [
            .reflective: reflectiveMessages,
            .inspirational: inspirationalMessages,
            .casual: casualMessages,
            .achievement: achievementMessages
        ]
    }
    
    // MARK: - Helper Methods
    
    /// **Internal Helper**: Maps message arrays to category names for logging
    private func categoryName(for messages: [String]) -> String {
        switch messages {
        case reflectiveMessages: return "Reflective"
        case inspirationalMessages: return "Inspirational"  
        case casualMessages: return "Casual"
        case achievementMessages: return "Achievement"
        default: return "Unknown"
        }
    }
    
    /// **Internal Helper**: Gets message array for a specific category
    private func getMessages(for category: MessageCategory) -> [String] {
        switch category {
        case .reflective: return reflectiveMessages
        case .inspirational: return inspirationalMessages
        case .casual: return casualMessages
        case .achievement: return achievementMessages
        }
    }
}

// MARK: - Supporting Types

/// **Message Categories**: Defines different types of notification messages
/// **Design**: Enum provides type safety and enables future expansion
/// **Extensibility**: Easy to add new categories (e.g., .motivational, .gratitude)
enum MessageCategory: String, CaseIterable {
    case reflective = "reflective"         // **Evening focus**: Daily reflection and processing
    case inspirational = "inspirational"   // **Creative focus**: Inspiration and idea capture  
    case casual = "casual"                // **Low pressure**: Friendly, approachable prompts
    case achievement = "achievement"       // **Progress focus**: Celebrating wins and growth
    
    var displayName: String {
        switch self {
        case .reflective: return "Reflective"
        case .inspirational: return "Inspirational"
        case .casual: return "Casual"
        case .achievement: return "Achievement"
        }
    }
    

    var description: String {
        switch self {
        case .reflective: return "Evening reflection and daily processing"
        case .inspirational: return "Creative inspiration and idea capture"
        case .casual: return "Friendly, low-pressure writing prompts"
        case .achievement: return "Celebrate progress and document wins"
        }
    }
}