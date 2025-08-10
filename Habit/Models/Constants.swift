//
//  Constants.swift
//  Habit
//
//  Created by Nazarii Zomko on 15.05.2023.
//

import SwiftUI

enum Constants {    
    // Toggle to enable/disable debug UI for the skill tree (borders, backgrounds, logs)
    static let debugSkillTreeUI: Bool = false
    
    /// Max width used to cap the skill tree visualization/root node.
    /// Keep children from overflowing on narrow screens while preserving centering.
    static let skillTreeMaxWidth: CGFloat = 300

    static let motivationPrompts: [LocalizedStringKey] = [
         "Keep it Up! 🙌",
         "🙏 Feel the force of the Habit",
         "❤️ You are amazing!",
         "Let's do this!",
         "Just start 😉",
         "Yes, you can! 💪"
    ]
    
    /// The size of the day of the week frame.
    ///
    /// It is used to ensure that the frame size of the checkmark (HabitRowView) and the frame size of the day of the week (HeaderView) remain consistent.
    static let dayOfTheWeekFrameSize: CGFloat = 32
}


