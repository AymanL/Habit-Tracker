struct HabitCardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var habit: Habit
    @State private var isPresentingEditHabitView = false
    
    var body: some View {
        Button {
            isPresentingEditHabitView = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(habit.title)
                        .font(.headline)
                    Spacer()
                    Text("\(habit.streak)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(habit.motivation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if habit.type == .counter {
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(habit.counterValue(for: Date()))")
                                .font(.system(size: 24, weight: .bold))
                            Text("/")
                                .font(.system(size: 24, weight: .bold))
                            Text("\(habit.target)")
                                .font(.system(size: 24, weight: .bold))
                        }
                        .foregroundColor(.primary)
                        
                        if let duration = habit.duration, duration > 0 {
                            Text("\(duration) min")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                habit.decrementCounter(for: Date())
                                try? viewContext.save()
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contentShape(Rectangle())
                            
                            Button(action: {
                                habit.incrementCounter(for: Date())
                                try? viewContext.save()
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contentShape(Rectangle())
                        }
                        .padding(.top, 4)
                    }
                } else {
                    HStack {
                        Spacer()
                        Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(habit.isCompletedToday ? .green : .gray)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isPresentingEditHabitView) {
            EditHabitView(habit: habit)
        }
    }
} 