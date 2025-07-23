class EventBottomSheetViewModel: ObservableObject {
    @Published var event: Event
    @Published var overallProgress: Double
    @Published var currentCount: Double
    @Published var totalCount: Double
    @Published var innerRanges: [[Date]] = []
    @Published var outerRange: [Date] = []
    @Published var isEnabled: Bool = false
    @Published var showAddAffirmation: Bool = false
    @Published var hasLoadedInitialData: Bool = false
    
        
    
     let isReadOnly: Bool
    
    init(event: Event, isReadOnly: Bool) {
        self.event = event
        self.isReadOnly = isReadOnly
        self.overallProgress = clamp(Double(event.percentage ?? 0), to: 0...100) / 100
        self.totalCount = Double(event.timesPerDay ?? 0)
        self.currentCount = Double(event.timesPerDay ?? 0) * (clamp(Double(event.percentage ?? 0), to: 0...100) / 100)
    }
    
    @MainActor
    func loadAutoCheckInData() async {
        print("DEBUG: Loading data for event: \(event.eventId)")
        
        let (outerRangeDates, innerRangesDates, calculatedPercentage) = await Task.detached(priority: .background) {
            return SQLiteManager.shared.fetchAutoCheckInData(for: self.event.dayId)
        }.value
        
        if let outerDates = outerRangeDates {
            self.outerRange = outerDates
        }
        
        if let innerDates = innerRangesDates {
            self.innerRanges = innerDates
        }
        
        if event.isAutoCheckin, let percentage = calculatedPercentage {
            if hasLoadedInitialData {
                withAnimation(.linear(duration: 0.3)) {
                    self.overallProgress = percentage
                }
            } else {
                self.overallProgress = percentage
                hasLoadedInitialData = true
            }
        }
    }
    
    
    
    
    func loadEventDataForDate(date: Date) async {
        print("Loading data for selected date: \(date)")

        // Step 1: Do heavy fetch work on background thread
        let result = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let data = SQLiteManager.shared.fetchAutoCheckInData(for: self.event.dayId)
                continuation.resume(returning: data) // resumes on calling thread (background)
            }
        }

        // Step 2: Unpack result on main thread
        let (outerRangeDates, innerRangesDates, calculatedPercentage) = result

        // ✅ Safe UI updates — we're on the main thread here
        if let outerDates = outerRangeDates {
            self.outerRange = outerDates
        }

        if let innerDates = innerRangesDates {
            self.innerRanges = innerDates
        }

        if event.isAutoCheckin, let percentage = calculatedPercentage {
            withAnimation(.linear(duration: 0.3)) {
                self.overallProgress = percentage
            }
        }
    }
    
    
    func updateEventPercentage() {
        if !event.isAutoCheckin && overallProgress > 0 {
            SQLiteManager.shared.updateEventPercentage(
                eventId: event.dayId,
                percentage: overallProgress
            )
        }
    }
    
    func incrementProgress() {
        guard currentCount < totalCount else { return }
        
        withAnimation(.linear(duration: 0.3)) {
            currentCount += 1
            overallProgress = Double((currentCount/totalCount))
        }
        updateEventPercentage()
    }
    
    func completeTask() {
        withAnimation(.linear(duration: 0.3)) {
            overallProgress = 1.0
        }
        updateEventPercentage()
    }
}

struct EventBottomSheetView: View {
    @StateObject private var viewModel: EventBottomSheetViewModel
        @Binding var isPresented: Bool
        @Binding var eventColor: String
        @State private var isActive = false
        
    init(event: Event, isPresented: Binding<Bool>, eventColor: Binding<String>, isReadOnly: Bool) {
        _viewModel = StateObject(wrappedValue: EventBottomSheetViewModel(event: event, isReadOnly: isReadOnly))
        _isPresented = isPresented
        _eventColor = eventColor
    }
    
    @State private var selectedDate: Date = Date()
        
        // Add dates that have data (last 7 days)
    @State private var daysWithData: [Date] = {
        var dates: [Date] = []
        let calendar = Calendar.gregorianUTC
        for offset in -4...2 {
            if let date = calendar.date(byAdding: .day, value: offset, to: Date()) {
                dates.append(date)
            }
        }
        return dates
    }()

    
    
        // Start date is 1 week back from today
        private var startDate: Date {
            Calendar.gregorianUTC.date(byAdding: .day, value: -4, to: Date()) ?? Date()
        }
        
        // End date is 2 days later from today
        private var endDate: Date {
            Calendar.gregorianUTC.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        }
    
    
    var body: some View {
        NavigationView {
            ZStack{
                VStack(spacing: 10) {
                    Spacer()
                        .frame(height: 10)
                    
                    // Header
                    HStack {
                        if(icons3d.contains(viewModel.event.icon))
                        {
                            Image(viewModel.event.icon)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color(hex: journalColorTheme[eventColor]?.main ?? "000000"))
                                .font(.system(size: 25))
                                .frame(width: 30, height: 30)
                                .padding(.all, 12.5)
                                .background(
                                    Circle()
                                        .fill(Color(hex: journalColorTheme[eventColor]?.main ?? "000000").opacity(0.1))
                                )
                        }
                        if(!icons3d.contains(viewModel.event.icon)){
                            Image(systemName: viewModel.event.icon)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color(hex: journalColorTheme[eventColor]?.main ?? "000000"))
                                .font(.system(size: 25))
                                .frame(width: 30, height: 30)
                                .padding(.all, 12.5)
                                .background(
                                    Circle()
                                        .fill(Color(hex: journalColorTheme[eventColor]?.main ?? "000000").opacity(0.1))
                                )
                        }
                       
                        VStack(alignment: .leading){
                            Text(viewModel.event.title.capitalizingFirstLetter())
                                .font(
                                    Font.custom("Outfit", size: 15)
                                        .weight(.semibold)
                                )
                                .foregroundColor(Color(hex: journalColorTheme[eventColor]?.main ?? "000000"))
                                .kerning(-0.5)
                            
                            Text((viewModel.event.description ?? "No description available").capitalizingFirstLetter())
                                .font(Font.custom("Outfit", size: 13).weight(.regular))
                                .foregroundColor(Color(hex:"8C8C8C"))
                                .kerning(-0.5)
                        }
                        Spacer()
                        
                        Circle()
                            .fill(Color(hex: journalColorTheme[eventColor]?.sub ?? "000000"))
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 0)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 4)
                            )
                            .onTapGesture{
                                HapticFeedbackManager.hapticFeedback(type: HapticFeedbackType.light)
                                let numbers = [1, 2, 3, 4].filter {
                                    if let lastChar = (eventColor).last, let lastNum = Int(String(lastChar)) {
                                        return $0 != lastNum
                                    }
                                    return true
                                }
                                
                                let themeNum = numbers.randomElement() ?? 1
                                let themeType = "theme\(themeNum)"
                                
                                if journalColorTheme[themeType] != nil {
                                    eventColor = themeType
                                }
                                
                                SQLiteManager.shared.updateEventColor(
                                    eventId: viewModel.event.eventId,
                                    color: eventColor
                                )
                            }
                        
                        // event.isPaused ?? false || event.isSnoozed ?? false
                        let onSnoozeAction: (() -> Void)? = (!(viewModel.event.isPaused ?? false) && !(viewModel.event.isSnoozed ?? false)) ? {
                            HapticFeedbackManager.hapticFeedback(type: .light)
                            SQLiteManager.shared.pauseDailyEventTracker(eventId: viewModel.event.dayId)
                            isPresented = false
                        } : nil
                        
                        let onPauseAction: (() -> Void)? = (!(viewModel.event.isPaused ?? false) && !(viewModel.event.isSnoozed ?? false)) ? {
                            HapticFeedbackManager.hapticFeedback(type: .light)
                            SQLiteManager.shared.pauseEvent(eventId: viewModel.event.eventId)
                            isPresented = false
                        } : nil

                        let onResumeAction: (() -> Void)? = ((viewModel.event.isPaused ?? false) || (viewModel.event.isSnoozed ?? false)) ? {
                            HapticFeedbackManager.hapticFeedback(type: .light)
                            SQLiteManager.shared.resumeEvent(eventId: viewModel.event.eventId)
                            SQLiteManager.shared.resumeDailyEventTracker(eventId: viewModel.event.dayId)
                            isPresented = false
                        } : nil

                        JournalBottomSheetMenuButtonView(
                            onEdit: {
                                HapticFeedbackManager.hapticFeedback(type: .light)
                                viewModel.showAddAffirmation = true
                                print("Edit tapped")
                            },
                            onPause: onPauseAction,
                            onSnooze: onSnoozeAction,
                            onResume: onResumeAction,
                            onFinish: {
                                print("finished tapped");
                                HapticFeedbackManager.hapticFeedback(type: .light)
                                SQLiteManager.shared.updateEventLifetime(eventId: viewModel.event.eventId)
                                SQLiteManager.shared.updateDailyEventCompletionStatus(eventId: viewModel.event.dayId)
                                isPresented = false
                            },
                            onDelete: {
                                HapticFeedbackManager.hapticFeedback(type: .light)
                                SQLiteManager.shared.deleteDayEvent(eventId: viewModel.event.eventId)
                                SQLiteManager.shared.deleteEvent(eventId: viewModel.event.eventId)
                                isPresented = false
                            }
                        )
                        .sheet(isPresented: $viewModel.showAddAffirmation, onDismiss: {
                            print("AddAffirmationView dismissed -- \(viewModel.showAddAffirmation)")
                            isPresented = false
                        })
                        {
                            NavigationStack {
                                AddAffirmationView(
                                    isPresented: $viewModel.showAddAffirmation,
                                    isNewAffirmation: false,
                                    event: viewModel.event,
                                    selectedCategory: viewModel.event.category,
                                    isAddAffirmation: false
                                )
                                .presentationCornerRadius(30)
                                .presentationDragIndicator(.visible)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollViewReader { proxy in
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                DateScrollView(
                                                    selectedDate: $selectedDate,
                                                    startDate: startDate,
                                                    endDate: endDate,
                                                    daysHaveData: daysWithData,
                                                    page: "Journal",
                                                    color: Color(hex: journalColorTheme[eventColor]?.sub ?? "000000")
                                                )
                                                .frame(height: 60)
                                                .padding(.bottom, -5)
                                                .onChange(of: selectedDate) { _, newDate in
                                                    Task {
                                                        await viewModel.loadEventDataForDate(date: newDate)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // Display selected date
                                        HStack(alignment: .center) {
                                            Spacer()
                                            Text(DateFormatter.customFormatter.string(from: selectedDate))
                                                .font(.custom("Outfit", size: 13))
                                                .foregroundColor(Color(hex: 0x1A1A1A, alpha: 0.6))
                                                .fontWeight(.regular)
                                            Spacer()
                                        }
                                        .padding(.bottom, -2)
                    
                    
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(height: 1)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.1))
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 7)
                        {
                            HStack(spacing: 4){
                                Image("daily")
                                Text("Daily")
                                    .font(Font.custom("Outfit", size: 13).weight(.regular))
                                    .foregroundColor(Color(hex:"8C8C8C"))
                                    .kerning(-0.5)
                            }
                            
                            if(viewModel.event.isPaused ?? false || viewModel.event.isSnoozed ?? false)
                            {
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.1), lineWidth: 8)
                                    Text((viewModel.event.isPaused ?? false) ? "Paused" : "Snoozed")
                                        .font(Font.custom("Outfit", size: 15))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.6))
                                    
                                        .frame(width: 101, alignment: .center)
                                }
                                .frame(width: 150, height: 150)
                            }
                            else{
                                if(!viewModel.event.isAutoCheckin){
                                    // Progress Circle
                                    ZStack {
                                        Circle()
                                            .stroke(Color(hex: journalColorTheme[eventColor]?.sub ?? "000000"), lineWidth: 8)
                                        Circle()
                                            .trim(from: 0, to: viewModel.overallProgress)
                                            .stroke(Color(hex: journalColorTheme[eventColor]?.sub ?? "000000").opacity(0.5), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                            .rotationEffect(.degrees(-90))
                                        
                                        GeometryReader { geometry in
                                            AnimArcShape(startAngle: Angle(degrees: -90), endAngle: Angle(degrees: -90 + viewModel.overallProgress * 360))
                                                .fill(
                                                    EllipticalGradient(
                                                        stops: [
                                                            Gradient.Stop(color: Color(red: 0.4, green: 0.45, blue: 0.91).opacity(0), location: 0.00),
                                                            Gradient.Stop(color: Color(red: 0.4, green: 0.45, blue: 0.91).opacity(0.2), location: 1.00),
                                                        ],
                                                        center: UnitPoint(x: 0.5, y: 0.5)
                                                    )
                                                )
                                        }
                                        
                                        VStack(spacing: 0) {
                                            HStack(alignment: .lastTextBaseline, spacing: 0){
                                                Text("\(Int(viewModel.overallProgress * 100))")
                                                    .font(
                                                        Font.custom("Outfit", size: 30)
                                                            .weight(.semibold)
                                                    )
                                                    .foregroundColor(Color(hex: journalColorTheme[eventColor]?.main ?? "000000"))
                                                Text("%")
                                                    .font(
                                                        Font.custom("Outfit", size: 20)
                                                    )
                                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                                            }
                                            
                                            HStack(spacing: 2) {
                                                // First part "Accomplished" with dynamic journal color
                                                Text("Accomplished")
                                                    .font(Font.custom("Outfit", size: 15).weight(.semibold))
                                                    .multilineTextAlignment(.center)
                                                    .foregroundColor(Color(hex: journalColorTheme[eventColor]?.main ?? "000000"))
                                                
                                                // Second part "Today" with fixed 60% opacity black
                                                Text("Today")
                                                    .font(Font.custom("Outfit", size: 15).weight(.regular))
                                                    .multilineTextAlignment(.center)
                                                    .foregroundColor(Color(hex: "1A1A1A", alpha: 0.6))
                                            }
                                            .frame(alignment: .center) // Increased width to accommodate both text
                                            
                                        }
                                    }
                                    .frame(width: 150, height: 150)
                                }
                                if(viewModel.event.isAutoCheckin)
                                {
                                    VStack(spacing: 10) {
                                        
                                        Spacer()
                                            .frame(height: 10)
                                        
                                        ZStack{
                                            MultiRangeClockView(
                                                ranges: viewModel.innerRanges,
                                                outerRange: viewModel.outerRange.isEmpty ? nil : viewModel.outerRange,
                                                isEnabled: $viewModel.isEnabled,
                                                eventColor: $eventColor
                                            )
                                            
                                            if(!viewModel.isEnabled && !viewModel.isReadOnly)
                                            {
                                                VStack{
                                                    Spacer()
                                                    Image("autofill")
                                                        .onTapGesture {
                                                            HapticFeedbackManager.hapticFeedback(type: .light)
                                                            viewModel.isEnabled = true
                                                        }
                                                        .offset(x: 110)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                            .frame(height: 10)
                                        
                                        if(viewModel.isEnabled)
                                        {
                                            HStack(spacing: 8){
                                                Image("recalculate")
                                                    .foregroundColor(.white)
                                                Text("Recalculate")
                                                    .font(Font.custom("Outfit", size: 15))
                                                    .multilineTextAlignment(.center)
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 40)
                                            .padding(.vertical, 10)
                                            .background(Color(hex: journalColorTheme[eventColor]?.main ?? "FFFFFF"))
                                            .cornerRadius(50)
                                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                            .onTapGesture {
                                                HapticFeedbackManager.hapticFeedback(type: .light)
                                                viewModel.isEnabled = false
                                                
                                                // Move heavy calculations to background thread
                                                DispatchQueue.global(qos: .userInitiated).async {
                                                    let updatedRanges = MultiRangeClockManager.shared.getStructuredTimeRanges()
                                                    
                                                    let convertedInnerRanges: [[Date]] = updatedRanges.innerSliders.map { innerRange in
                                                        let calendar = Calendar.gregorianUTC
                                                        let today = Date()
                                                        
                                                        var startComponents = calendar.dateComponents([.year, .month, .day], from: today)
                                                        startComponents.hour = innerRange.startHour
                                                        startComponents.minute = innerRange.startMinute
                                                        
                                                        var endComponents = calendar.dateComponents([.year, .month, .day], from: today)
                                                        endComponents.hour = innerRange.endHour
                                                        endComponents.minute = innerRange.endMinute
                                                        
                                                        if let startDate = calendar.date(from: startComponents),
                                                           let endDate = calendar.date(from: endComponents) {
                                                            return [startDate, endDate]
                                                        }
                                                        return []
                                                    }.filter { !$0.isEmpty }
                                                    
                                                    let outerTimeRange = updatedRanges.outerSlider
                                                    let calendar = Calendar.gregorianUTC
                                                    let today = Date()
                                                    
                                                    var startComponents = calendar.dateComponents([.year, .month, .day], from: today)
                                                    startComponents.hour = outerTimeRange.startHour
                                                    startComponents.minute = outerTimeRange.startMinute
                                                    
                                                    var endComponents = calendar.dateComponents([.year, .month, .day], from: today)
                                                    endComponents.hour = outerTimeRange.endHour
                                                    endComponents.minute = outerTimeRange.endMinute
                                                    
                                                    var newOuterRange: [Date] = []
                                                    var newEvent: Event?
                                                    
                                                    if let startDate = calendar.date(from: startComponents),
                                                       let endDate = calendar.date(from: endComponents) {
                                                        newOuterRange = [startDate, endDate]
                                                        
                                                        let timeFormatter = DateFormatter(utcIdentifier: "UTC")
                                                        timeFormatter.dateFormat = "HH:mm"
                                                        let newStartTime = timeFormatter.string(from: startDate) + ":00"
                                                        let newEndTime = timeFormatter.string(from: endDate) + ":00"
                                                        
                                                        let dateFormatter = DateFormatter(utcIdentifier: "UTC")
                                                        dateFormatter.dateFormat = "yyyy-MM-dd"
                                                        let todayStr = dateFormatter.string(from: Date())
                                                        
                                                        // Create new event object
                                                        newEvent = Event(
                                                            dayId: viewModel.event.dayId,
                                                            eventId: viewModel.event.eventId,
                                                            title: viewModel.event.title,
                                                            category: viewModel.event.category,
                                                            percentage: viewModel.event.percentage,
                                                            isAutoCheckin: viewModel.event.isAutoCheckin,
                                                            isUpcomingEvent: viewModel.event.isUpcomingEvent,
                                                            mainCatagory: viewModel.event.mainCatagory,
                                                            date: viewModel.event.date,
                                                            description: viewModel.event.description,
                                                            completedCount: viewModel.event.completedCount,
                                                            uncompletedCount: viewModel.event.uncompletedCount,
                                                            notes: viewModel.event.notes,
                                                            userConfidence: viewModel.event.userConfidence,
                                                            datesFailed: viewModel.event.datesFailed,
                                                            timesPerDay: viewModel.event.timesPerDay,
                                                            isPaused: viewModel.event.isPaused,
                                                            isSnoozed: viewModel.event.isSnoozed,
                                                            isEventCompleted: viewModel.event.isEventCompleted,
                                                            createdAt: viewModel.event.createdAt,
                                                            color: viewModel.event.color,
                                                            isDefaultEvent: viewModel.event.isDefaultEvent,
                                                            isLifeTimeEvent: viewModel.event.isLifeTimeEvent,
                                                            icon: viewModel.event.icon,
                                                            startDate: todayStr,
                                                            endDate: todayStr,
                                                            startTime: newStartTime,
                                                            endTime: newEndTime,
                                                            repeatFrequency: viewModel.event.repeatFrequency,
                                                            environment: viewModel.event.environment,
                                                            activityType: viewModel.event.activityType,
                                                            surroundings: viewModel.event.surroundings,
                                                            location: viewModel.event.location,
                                                            universalid: viewModel.event.universalid,
                                                            timeBuffer: viewModel.event.timeBuffer,
                                                            phonePickup: viewModel.event.phonePickup,
                                                            chargingState: viewModel.event.chargingState,
                                                            start_reminder: ""
                                                        )
                                                    }
                                                    
                                                    // Calculate progress
                                                    var newOverallProgress: Double = 0.0
                                                    if let outerStart = newOuterRange.first,
                                                       let outerEnd = newOuterRange.last {
                                                        let calendar = Calendar.gregorianUTC
                                                        var totalValidInnerMinutes: Double = 0
                                                        var totalOuterMinutes: Double = 0
                                                        
                                                        if outerEnd < outerStart {
                                                            // Handle overnight case calculations
                                                            let (validMinutes, totalMinutes) = calculateOvernightProgress(
                                                                outerStart: outerStart,
                                                                outerEnd: outerEnd,
                                                                innerRanges: convertedInnerRanges,
                                                                calendar: calendar
                                                            )
                                                            totalValidInnerMinutes = validMinutes
                                                            totalOuterMinutes = totalMinutes
                                                        } else {
                                                            // Handle normal case calculations
                                                            let (validMinutes, totalMinutes) = calculateNormalProgress(
                                                                outerStart: outerStart,
                                                                outerEnd: outerEnd,
                                                                innerRanges: convertedInnerRanges,
                                                                calendar: calendar
                                                            )
                                                            totalValidInnerMinutes = validMinutes
                                                            totalOuterMinutes = totalMinutes
                                                        }
                                                        
                                                        if totalOuterMinutes > 0 {
                                                            newOverallProgress = min(totalValidInnerMinutes / totalOuterMinutes, 1.0)
                                                        }
                                                    }
                                                    
                                                    // Update database in background
                                                    SQLiteManager.shared.updateAutoCheckInData(
                                                        eventId: viewModel.event.dayId,
                                                        innerRanges: convertedInnerRanges,
                                                        outerRange: newOuterRange,
                                                        overallProgress: newOverallProgress
                                                    )
                                                    
                                                    // Update UI on main thread
                                                    DispatchQueue.main.async {
                                                        if let newEvent = newEvent {
                                                            viewModel.event = newEvent
                                                        }
                                                        viewModel.outerRange = newOuterRange
                                                        viewModel.innerRanges = convertedInnerRanges
                                                        withAnimation(.linear(duration: 0.3)) {
                                                            viewModel.overallProgress = newOverallProgress
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    HStack(alignment: .lastTextBaseline, spacing: 0){
                                        Text("\(Int(viewModel.overallProgress * 100))")
                                            .font(
                                                Font.custom("Outfit", size: 30)
                                                    .weight(.semibold)
                                            )
                                            .foregroundColor(Color(hex: journalColorTheme[eventColor ?? "theme1"]?.main ?? "000000"))
                                        Text("%")
                                            .font(
                                                Font.custom("Outfit", size: 20)
                                            )
                                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                                    }
                                    HStack(spacing: 2) {
                                        // First part "Accomplished" with dynamic journal color
                                        Text("Accomplished")
                                            .font(Font.custom("Outfit", size: 15).weight(.semibold))
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color(hex: journalColorTheme[eventColor]?.main ?? "000000"))
                                        
                                        // Second part "Today" with fixed 60% opacity black
                                        Text("Today")
                                            .font(Font.custom("Outfit", size: 15).weight(.regular))
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color(hex: "1A1A1A", alpha: 0.6))
                                    }
                                    .frame(alignment: .center) // Increased width to accommodate both text
                                        .padding(.top, -10)
                                }
                            }
                            
                            // Stats Cards
                            HStack(spacing: 0) {
                                StatCard(
                                    value: Int(viewModel.event.completedCount ?? 0),
                                    label: "days",
                                    subtitle: "Finished",
                                    color: .green
                                )
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .frame(width: 0.5, height: 27)
                                    .background(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.4))
                                StatCard(
                                    value: Int(viewModel.event.uncompletedCount ?? 0),
                                    label: "days",
                                    subtitle: "Missed",
                                    color: .red
                                )
                            }
                            
                            if(!viewModel.event.isAutoCheckin && viewModel.overallProgress < 1.0 && !viewModel.isReadOnly && !(viewModel.event.isPaused ?? false) && !(viewModel.event.isSnoozed ?? false))
                            {
                                HStack{
                                    Text("Have you done this today?")
                                        .font(Font.custom("Outfit", size: 15))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.black)
                                        .onDisappear{
                                            if(!viewModel.event.isAutoCheckin && viewModel.overallProgress > 0)
                                            {
                                                SQLiteManager.shared.updateEventPercentage(
                                                    eventId: viewModel.event.dayId,
                                                    percentage: viewModel.overallProgress
                                                )
                                            }
                                        }
                                    
                                    if(viewModel.totalCount <= 1)
                                    {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .frame(width: 30, height: 30, alignment: .center)
                                            .background(Color(hex: journalColorTheme[eventColor ?? "theme1"]?.main ?? "000000"))
                                            .cornerRadius(12)
                                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                            .onTapGesture {
                                                HapticFeedbackManager.hapticFeedback(type: .light)
                                                withAnimation(.linear(duration: 0.3)) {
                                                    viewModel.overallProgress = 1.0
                                                }
                                            }
                                    }
                                    else{
                                        HStack(spacing: 0){
                                            Text("\(Int(viewModel.currentCount))")
                                                .font(
                                                    Font.custom("Outfit", size: 15)
                                                        .weight(.bold)
                                                )
                                                .foregroundColor(Color.init(hex: 0x6673E7))
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(.black)
                                            
                                            Text(" / \(Int(viewModel.totalCount))")
                                                .font(Font.custom("Outfit", size: 15))
                                                .foregroundColor(Color.init(hex: 0x1A1A1A).opacity(0.6))
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(.black)
                                        }
                                        Image(systemName: "plus")
                                            .foregroundStyle(.white)
                                            .frame(width: 30, height: 30, alignment: .center)
                                            .background(Color(red: 0.4, green: 0.45, blue: 0.91))
                                            .cornerRadius(12)
                                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                            .onTapGesture {
                                                HapticFeedbackManager.hapticFeedback(type: .light)
                                                if(viewModel.currentCount < viewModel.totalCount)
                                                {
                                                    withAnimation(.linear(duration: 0.3)) {
                                                        viewModel.currentCount += 1;
                                                        viewModel.overallProgress = Double((viewModel.currentCount/viewModel.totalCount))
                                                    }
                                                }
                                            }
                                    }
                                }
                            }
                            
                            EventTrendLineView(event: viewModel.event , eventColor: .constant(journalColorTheme[eventColor]?.main ?? "ffffff"))
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(hex: journalColorTheme[eventColor]?.widg ?? "ffffff"))
                                        .stroke(Color(hex: journalColorTheme[eventColor]?.sub ?? "ffffff"), lineWidth: 1)
                                        .shadow(color: Color(red: 0.65, green: 0.65, blue: 0.65).opacity(0.25), radius: 5, x: 0, y: 0)
                                )
                                .padding(.horizontal, 10)
                            //.fill(Color(hex: journalColorTheme[event.color ?? "theme1"]?.widg ?? "000000"))
                            
                            EventHeatmapView(eventId: viewModel.event.eventId,baseColor: UIColor(Color(hex: journalColorTheme[eventColor]?.main ?? "ffffff")))
                                .frame(height: 180)
                                .padding(.vertical, 20)
                                .padding(.horizontal, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(hex: journalColorTheme[eventColor]?.widg ?? "ffffff"))
                                        .stroke(Color(hex: journalColorTheme[eventColor]?.sub ?? "ffffff"), lineWidth: 1)
                                        .shadow(color: Color(red: 0.65, green: 0.65, blue: 0.65).opacity(0.25), radius: 5, x: 0, y: 0)
                                )
                                .padding(.horizontal, 10)
                            
                            Spacer()
                                .frame(height: 60)
                        }
                    }
                }
                .navigationBarHidden(true)
                
                VStack{
                    Spacer()
                    NavigationLink(
                        destination: ReflectionsView(event: viewModel.event, eventColor: $eventColor),
                        isActive: $isActive
                    ) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "4D4D4D"))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "pencil.and.scribble")
                                .font(.system(size: 25, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .onChange(of: isActive) {
                        HapticFeedbackManager.hapticFeedback(type: .light)
                    }
                    .padding(.all, 5)
                }
                .frame(width: UIScreen.main.bounds.width * 0.9, alignment: .trailing)
            }
        }
        .environment(\.sizeCategory, .large)
        .task {
            await viewModel.loadAutoCheckInData()
          //  async let datesTask = viewModel.loadDatesWithData()
        
        }
    }
}


// Add these methods to your EventBottomSheetViewModel class





struct StatCard: View {
    let value: Int
    let label: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(subtitle == "Finished" ? "event_completed" : "event_missed")
                .foregroundColor(color)
            VStack(alignment: .leading) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(value/10 < 1 ? "0" : "")\(value)")
                        .font(
                            Font.custom("Outfit", size: 21)
                                .weight(.semibold)
                        )
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    Text(label)
                        .font(
                            Font.custom("Outfit", size: 15)
                                .weight(.regular)
                        )
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1)).opacity(0.5)
                }
                
                Text(subtitle)
                    .font(Font.custom("Outfit", size: 13))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.6))
            }
        }
        .padding()
        .cornerRadius(12)
    }
}

struct AnimArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var animatableData: AnimatablePair<Double, Double> {
        get {
            AnimatablePair(startAngle.degrees, endAngle.degrees)
        }
        set {
            startAngle = Angle(degrees: newValue.first)
            endAngle = Angle(degrees: newValue.second)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

import Foundation
import SQLite3

private func calculateOvernightProgress(
    outerStart: Date,
    outerEnd: Date,
    innerRanges: [[Date]],
    calendar: Calendar
) -> (validMinutes: Double, totalMinutes: Double) {
    var totalValidInnerMinutes: Double = 0
    
    var startMidnightComponents = calendar.dateComponents([.year, .month, .day], from: outerStart)
    startMidnightComponents.day! += 1
    startMidnightComponents.hour = 0
    startMidnightComponents.minute = 0
    startMidnightComponents.second = 0
    
    var endMidnightComponents = calendar.dateComponents([.year, .month, .day], from: outerEnd)
    endMidnightComponents.hour = 0
    endMidnightComponents.minute = 0
    endMidnightComponents.second = 0
    
    guard let startMidnight = calendar.date(from: startMidnightComponents),
          let endMidnight = calendar.date(from: endMidnightComponents) else {
        return (0, 0)
    }
    
    let firstHalfMinutes = calendar.dateComponents([.minute], from: outerStart, to: startMidnight).minute ?? 0
    let secondHalfMinutes = calendar.dateComponents([.minute], from: endMidnight, to: outerEnd).minute ?? 0
    let totalOuterMinutes = Double(firstHalfMinutes + secondHalfMinutes)
    
    for range in innerRanges {
        let innerStart = range[0]
        let innerEnd = range[1]
        
        if innerEnd < innerStart {
            if innerStart <= startMidnight && innerStart >= outerStart {
                totalValidInnerMinutes += Double(calendar.dateComponents([.minute], from: innerStart, to: startMidnight).minute ?? 0)
            }
            if innerEnd >= endMidnight && innerEnd <= outerEnd {
                totalValidInnerMinutes += Double(calendar.dateComponents([.minute], from: endMidnight, to: innerEnd).minute ?? 0)
            }
        } else {
            if innerEnd >= outerStart && innerStart <= startMidnight {
                let overlapStart = max(innerStart, outerStart)
                let overlapEnd = min(innerEnd, startMidnight)
                totalValidInnerMinutes += Double(calendar.dateComponents([.minute], from: overlapStart, to: overlapEnd).minute ?? 0)
            }
            if innerEnd >= endMidnight && innerStart <= outerEnd {
                let overlapStart = max(innerStart, endMidnight)
                let overlapEnd = min(innerEnd, outerEnd)
                totalValidInnerMinutes += Double(calendar.dateComponents([.minute], from: overlapStart, to: overlapEnd).minute ?? 0)
            }
        }
    }
    
    return (totalValidInnerMinutes, totalOuterMinutes)
}

// Helper function for normal progress calculation
private func calculateNormalProgress(
    outerStart: Date,
    outerEnd: Date,
    innerRanges: [[Date]],
    calendar: Calendar
) -> (validMinutes: Double, totalMinutes: Double) {
    var totalValidInnerMinutes: Double = 0
    let totalOuterMinutes = Double(calendar.dateComponents([.minute], from: outerStart, to: outerEnd).minute ?? 0)
    
    for range in innerRanges {
        let innerStart = range[0]
        let innerEnd = range[1]
        
        if innerEnd > outerStart && innerStart < outerEnd {
            let overlapStart = max(innerStart, outerStart)
            let overlapEnd = min(innerEnd, outerEnd)
            let validMinutes = calendar.dateComponents([.minute], from: overlapStart, to: overlapEnd).minute ?? 0
            totalValidInnerMinutes += Double(max(0, validMinutes))
        }
    }
    
    return (totalValidInnerMinutes, totalOuterMinutes)
}

struct AutoCheckInData: Codable {
    let value: Double
    let percentage: Double
    let dataTracking: [String: Double]
    
    private enum CodingKeys: String, CodingKey {
        case value
        case percentage
        case dataTracking
    }
}

extension SQLiteManager {
    
        // Helper function to create a date range from time strings
        private func createDateRangeFromTimeStrings(date: Date, startTime: String, endTime: String) -> [Date]? {
            let calendar = Calendar.gregorianUTC
            let timeFormatter = DateFormatter(utcIdentifier: "UTC")
            timeFormatter.dateFormat = "HH:mm:ss"
            
            guard let startComponents = timeFormatter.date(from: startTime),
                  let endComponents = timeFormatter.date(from: endTime) else {
                return nil
            }
            
            // Extract hour, minute, second from the parsed dates
            let startHour = calendar.component(.hour, from: startComponents)
            let startMinute = calendar.component(.minute, from: startComponents)
            let startSecond = calendar.component(.second, from: startComponents)
            
            let endHour = calendar.component(.hour, from: endComponents)
            let endMinute = calendar.component(.minute, from: endComponents)
            let endSecond = calendar.component(.second, from: endComponents)
            
            // Create new dates with the selected date's year, month, day, but with the time components from the database
            var startDateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            startDateComponents.hour = startHour
            startDateComponents.minute = startMinute
            startDateComponents.second = startSecond
            
            var endDateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            endDateComponents.hour = endHour
            endDateComponents.minute = endMinute
            endDateComponents.second = endSecond
            
            if let startDate = calendar.date(from: startDateComponents),
               let endDate = calendar.date(from: endDateComponents) {
                return [startDate, endDate]
            }
            
            return nil
        }
    
    
    
    
    
    
    
    // Helper struct to decode both data sources
    private struct CombinedAutoCheckInData: Codable {
        let value: Double
        let percentage: Double
        let dataTracking: [String: Double]
        
        private enum CodingKeys: String, CodingKey {
            case value
            case percentage
            case dataTracking
        }
    }
    
    func fetchAutoCheckInData(for eventId: Int) -> (outerRange: [Date]?, innerRanges: [[Date]]?, overallPercentage: Double?) {
        
        guard let universalid = SQLiteManager.shared.getLastUniversalID(),
              !universalid.isEmpty else {
            return (nil, nil, nil)
        }
        
        let query = """
                SELECT data, user_data, start_time, end_time, date, percentage
                FROM daily_event_tracker 
                WHERE id = ? AND universalid = '\(universalid)';
            """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("DEBUG: Error preparing statement: \(String(cString: sqlite3_errmsg(db)))")
            return (nil, nil, nil)
        }
        
        sqlite3_bind_int(statement, 1, Int32(eventId))
        
        defer {
            sqlite3_finalize(statement)
        }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            print("DEBUG: No rows found for eventId: \(eventId)")
            return (nil, nil, nil)
        }
        
        let percentage = Int(sqlite3_column_int(statement, 5))
        
        print("PERCENTAGE -- \(percentage)")
        
        // Parse outer range first
        var outerRange: [Date]?
        if let startTimeStr = sqlite3_column_text(statement, 2),
           let endTimeStr = sqlite3_column_text(statement, 3) {
            let startTimeString = String(cString: startTimeStr)
            let endTimeString = String(cString: endTimeStr)
            
            let calendar = Calendar.gregorianUTC
            let today = Date()
            
            let startComponents = startTimeString.split(separator: ":")
            let endComponents = endTimeString.split(separator: ":")
            
            if startComponents.count >= 2 && endComponents.count >= 2,
               let startHour = Int(startComponents[0]),
               let startMinute = Int(startComponents[1]),
               let endHour = Int(endComponents[0]),
               let endMinute = Int(endComponents[1]),
               let startDate = calendar.date(bySettingHour: startHour,
                                             minute: startMinute,
                                             second: 0,
                                             of: today),
               let endDate = calendar.date(bySettingHour: endHour,
                                           minute: endMinute,
                                           second: 0,
                                           of: today) {
                outerRange = [startDate, endDate]
                print("DEBUG: Successfully created outer range: \(startDate) to \(endDate)")
            }
        }
        
        // Parse and merge both data sources
        var allTimeRanges: [String: Double] = [:]
        
        // Function to merge data from a column
        func mergeDataFromColumn(_ columnIndex: Int32) {
            guard let dataBlob = sqlite3_column_text(statement, columnIndex) else { return }
            let dataString = String(cString: dataBlob)
            
            do {
                let decodedData = try JSONDecoder().decode(CombinedAutoCheckInData.self, from: dataString.data(using: .utf8)!)
                print("DECODED DATE -- \(decodedData)")
                // Merge time ranges, taking the maximum value if there's overlap
                for (timeRange, value) in decodedData.dataTracking {
                    if let existingValue = allTimeRanges[timeRange] {
                        allTimeRanges[timeRange] = max(existingValue, value)
                    } else {
                        allTimeRanges[timeRange] = value
                    }
                }
            } catch {
                print("DEBUG: JSON parsing error for column \(columnIndex): \(error)")
            }
        }
        
        // Merge data from both columns
        mergeDataFromColumn(0) // data column
        mergeDataFromColumn(1) // user_data column
        
        print("COMBINED RANGES -- \(allTimeRanges)")
        
        // Process merged time ranges
        let dateFormatter = DateFormatter(utcIdentifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        
        var ranges: [[Date]] = []
        
        // Sort time ranges by start time
        let sortedTimeRanges = allTimeRanges.sorted { key1, key2 in
            let start1 = key1.key.split(separator: "_")[0]
            let start2 = key2.key.split(separator: "_")[0]
            return start1 < start2
        }
        
        print("SORTED RANGES -- \(sortedTimeRanges)")
        
        for (timeRange, value) in sortedTimeRanges {
            guard value > 0 else { continue }
            
            let components = timeRange.split(separator: "_")
            guard components.count == 2 else { continue }
            
            let startTimeStr = String(components[0])
            let endTimeStr = String(components[1])
            
            let formats = [
                "yyyy-MM-dd HH:mm:ss.SSSSSS",
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd HH:mm"
            ]
            
            var startDate: Date?
            var endDate: Date?
            
            for format in formats {
                dateFormatter.dateFormat = format
                if startDate == nil {
                    startDate = dateFormatter.date(from: startTimeStr)
                }
                if endDate == nil {
                    endDate = dateFormatter.date(from: endTimeStr)
                }
                if startDate != nil && endDate != nil {
                    break
                }
            }
            
            guard let start = startDate, let end = endDate else {
                continue
            }
            
            ranges.append([start, end])
        }
        
        let optimizedRanges = mergeConnectedRanges(ranges)
        
        var overallPercentage: Double = 0
        
        // Calculate overall percentage by summing the actual tracked values
        if let outerRange = outerRange,
           let outerStart = outerRange.first,
           let outerEnd = outerRange.last {
            
            let calendar = Calendar.gregorianUTC
            var totalOuterMinutes: Double = 0
            
            // Handle overnight case
            if outerEnd < outerStart {
                totalOuterMinutes = calculateOuterRangeMinutesForOvernight(
                    outerStart: outerStart,
                    outerEnd: outerEnd,
                    calendar: calendar
                )
            } else {
                // Normal case (no overnight)
                totalOuterMinutes = Double(calendar.dateComponents([.minute], from: outerStart, to: outerEnd).minute ?? 0)
            }
            
            // Sum up the actual tracked values directly from the allTimeRanges dictionary
            var totalValidInnerMinutes: Double = 0
            for (_, value) in allTimeRanges {
                // Only count positive values
                if value > 0 {
                    totalValidInnerMinutes += value
                }
            }
            
            print("DEBUG: Total valid minutes (from tracking data): \(totalValidInnerMinutes) out of \(totalOuterMinutes)")
            
            if totalOuterMinutes > 0 {
                overallPercentage = min(totalValidInnerMinutes / totalOuterMinutes, 1.0)
            }
        }
        
        print("Overall Percentages: \(overallPercentage)")
        
        print((outerRange, optimizedRanges, Double(percentage/100), overallPercentage))
        
        return (outerRange, optimizedRanges, Double(overallPercentage))
    }
    
    // Enhanced merge function with smarter gap handling
    private func mergeConnectedRanges(_ ranges: [[Date]]) -> [[Date]] {
        let calendar = Calendar.gregorianUTC
        guard !ranges.isEmpty else { return [] }
        
        var mergedRanges: [[Date]] = []
        var currentRange = ranges[0]
        
        for i in 1..<ranges.count {
            let nextRange = ranges[i]
            
            // Calculate gap between ranges in minutes
            let gapMinutes = calendar.dateComponents(
                [.minute],
                from: currentRange[1],
                to: nextRange[0]
            ).minute ?? Int.max
            
            // Merge if overlap or gap is less than threshold (30 minutes)
            if gapMinutes <= 0 {
                currentRange = [
                    min(currentRange[0], nextRange[0]),
                    max(currentRange[1], nextRange[1])
                ]
            } else {
                mergedRanges.append(currentRange)
                currentRange = nextRange
            }
        }
        
        mergedRanges.append(currentRange)
        return mergedRanges
    }
    
    func updateAutoCheckInData(eventId: Int, innerRanges: [[Date]], outerRange: [Date], overallProgress: Double) {
        let timeFormatter = DateFormatter(utcIdentifier: "UTC")
        timeFormatter.dateFormat = "HH:mm"
        
        guard let universalid = SQLiteManager.shared.getLastUniversalID(),
              !universalid.isEmpty else {
            return
        }
        
        guard outerRange.count == 2,
              let startDate = outerRange.first,
              let endDate = outerRange.last else {
            print("Invalid outer range")
            return
        }
        
        let startTime = timeFormatter.string(from: startDate)
        let endTime = timeFormatter.string(from: endDate)
        
        // Format inner ranges for data JSON
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        
        var dataTracking: [String: Double] = [:]
        
        for range in innerRanges {
            guard range.count == 2,
                  let rangeStart = range.first,
                  let rangeEnd = range.last else {
                continue
            }
            
            let key = "\(dateFormatter.string(from: rangeStart))_\(dateFormatter.string(from: rangeEnd))"
            
            // Calculate duration in minutes for the value
            let duration = Calendar.gregorianUTC.dateComponents([.minute], from: rangeStart, to: rangeEnd)
            let minutes = Double(duration.minute ?? 0)
            dataTracking[key] = minutes
        }
        
        // Create AutoCheckInData structure
        let autoCheckInData = AutoCheckInData(
            value: 0.0, // This could be sum of all minutes if needed
            percentage: overallProgress * 100,
            dataTracking: dataTracking
        )
        
        // Convert to JSON
        guard let jsonData = try? JSONEncoder().encode(autoCheckInData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("Failed to encode data to JSON")
            return
        }
        
        // Prepare the update query
        let query = """
                    UPDATE daily_event_tracker 
                    SET start_time = ?,
                        end_time = ?,
                        user_data = ?,
                        percentage = ?
                    WHERE id = ? AND universalid = '\(universalid)';
                """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing statement: \(String(cString: sqlite3_errmsg(db)))")
            return
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        // Bind parameters
        sqlite3_bind_text(statement, 1, (startTime as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (endTime as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (jsonString as NSString).utf8String, -1, nil)
        sqlite3_bind_double(statement, 4, overallProgress * 100) // Convert to percentage
        sqlite3_bind_int(statement, 5, Int32(eventId))
        
        // Execute the update
        if sqlite3_step(statement) != SQLITE_DONE {
            print("Error updating record: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("Successfully updated auto check-in data")
        }
    }
}

private func formatTimeRangeKey(start: Date, end: Date) -> String? {
    let dateFormatter = DateFormatter(utcIdentifier: "UTC")
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return "\(dateFormatter.string(from: start))_\(dateFormatter.string(from: end))"
}

private func calculateValidMinutesForOvernight(
    innerStart: Date,
    innerEnd: Date,
    outerStart: Date,
    outerEnd: Date,
    calendar: Calendar
) -> Double {
    let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: outerStart)!
    let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: outerStart)!
    var totalMinutes: Double = 0
    
    // Check first half (start to midnight)
    if innerEnd > outerStart {
        let overlapStart = max(innerStart, outerStart)
        let overlapEnd = min(innerEnd, endOfDay)
        let minutes = calendar.dateComponents([.minute], from: overlapStart, to: overlapEnd).minute ?? 0
        totalMinutes += Double(max(0, minutes))
    }
    
    // Check second half (midnight to end)
    if innerStart < outerEnd {
        let overlapStart = max(innerStart, startOfDay)
        let overlapEnd = min(innerEnd, outerEnd)
        let minutes = calendar.dateComponents([.minute], from: overlapStart, to: overlapEnd).minute ?? 0
        totalMinutes += Double(max(0, minutes))
    }
    
    return totalMinutes
}

private func calculateOuterRangeMinutesForOvernight(
    outerStart: Date,
    outerEnd: Date,
    calendar: Calendar
) -> Double {
    let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: outerStart)!
    let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: outerStart)!
    
    // Calculate minutes from start to midnight
    let firstHalfMinutes = calendar.dateComponents([.minute], from: outerStart, to: endOfDay).minute ?? 0
    // Calculate minutes from midnight to end
    let secondHalfMinutes = calendar.dateComponents([.minute], from: startOfDay, to: outerEnd).minute ?? 0
    
    return Double(firstHalfMinutes + secondHalfMinutes + 1) // Add 1 for the midnight minute
}


\EventBottomSheetViewModel.isEnabled is isolated to the main actor. Accessing it via Binding from a different actor will cause undefined behaviors, and potential data races; This warning will become a runtime crash in a future version of SwiftUI.
\EventBottomSheetViewModel.showAddAffirmation is isolated to the main actor. Accessing it via Binding from a different actor will cause undefined behaviors, and potential data races; This warning will become a runtime crash in a future version of SwiftUI.

loadEventDataForDate
    )
                        .sheet(isPresented: $viewModel.showAddAffirmation, onDismiss: {
                            print("AddAffirmationView dismissed -- \(viewModel.showAddAffirmation)")
                            isPresented = false
                        })
  ZStack{
                                            MultiRangeClockView(
                                                ranges: viewModel.innerRanges,
                                                outerRange: viewModel.outerRange.isEmpty ? nil : viewModel.outerRange,
                                                isEnabled: $viewModel.isEnabled,
                                                eventColor: $eventColor
                                            )