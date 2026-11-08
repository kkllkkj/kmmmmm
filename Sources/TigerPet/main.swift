import AppKit
import SwiftUI

struct Todo: Codable, Identifiable {
    var id = UUID()
    var title: String
    var reward: Int
    var done = false
    var day: String
}
struct Reflection: Codable {
    var mood = "平静"
    var learning = ""
    var note = ""
}
struct Food: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let price: Int
    var hot = false
    static let menu = [
        Food(id:"tea",name:"热奶茶",emoji:"🧋",price:20,hot:true),
        Food(id:"coffee",name:"美式",emoji:"☕️",price:15),
        Food(id:"cake",name:"小蛋糕",emoji:"🍰",price:25),
        Food(id:"ramen",name:"热拉面",emoji:"🍜",price:30,hot:true),
        Food(id:"egg",name:"鸡蛋",emoji:"🥚",price:5),
        Food(id:"steak",name:"牛排",emoji:"🥩",price:40),
        Food(id:"oatmilk",name:"燕麦牛奶",emoji:"🥛",price:15),
        Food(id:"bento",name:"盒饭",emoji:"🍱",price:25),
        Food(id:"dumpling",name:"饺子",emoji:"🥟",price:20),
        Food(id:"strawberry",name:"草莓",emoji:"🍓",price:10),
        Food(id:"blueberry",name:"蓝莓",emoji:"🫐",price:10),
        Food(id:"avocado",name:"牛油果",emoji:"🥑",price:15),
        Food(id:"seafood",name:"海鲜",emoji:"🦐",price:35),
        Food(id:"sweetpotato",name:"烤红薯",emoji:"🍠",price:10,hot:true),
        Food(id:"chicken",name:"鸡胸肉",emoji:"🍗",price:20),
        Food(id:"greens",name:"绿叶菜",emoji:"🥬",price:5)
    ]
}
struct FocusLog: Codable, Identifiable {
    var id = UUID()
    var task: String
    var mode: String
    var seconds: Double
    var date: Date
}
struct FocusSession: Codable {
    var taskID: UUID
    var title: String
    var mode: String
    var accumulated: Double = 0
    var started: Date?
    func duration(at now: Date = Date()) -> Double { accumulated + max(0, started.map { now.timeIntervalSince($0) } ?? 0) }
}
struct Saved: Codable {
    var points = 0
    var meals = 0
    var tasks: [Todo] = []
    var reflections: [String: Reflection] = [:]
    // Optional fields keep old saves compatible.
    var affection: Int? = 0
    var pantry: [String:Int]? = [:]
    var focusLogs: [FocusLog]? = []
    var session: FocusSession?
    var quietSetting: Bool? = false
    var activityInterval: Int? = 120
    var quoteInterval: Int? = 300
    var autoFullscreen: Bool? = true
}
func dayKey(_ date: Date = Date()) -> String {
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
}
final class Store: ObservableObject {
    @Published var data = Saved()
    @Published var reducedMotion = false
    @Published var eatingFood: Food?
    @Published var activity = "陪伴"
    @Published var facing = 1.0
    @Published var actionStarted = Date()
    @Published var speech = "今天也一起慢慢来吧！"
    @Published var quiet = false { didSet { data.quietSetting = quiet; save() } }
    @Published var saveError: String?
    let file: URL
    private var actionToken = UUID()
    private var lastQuote = -1
    private var speechLockedUntil = Date.distantPast
    static let quotes = [
        "不能成为一棵大树也没关系，那就成为大树所必需的阳光和水分吧。",
        "人不是因为幸福而笑，而是因为笑而幸福。", "你要最爱你自己。", "你能成为你自己的春天。",
        "我们常常思考我们想要得到什么，而往往忽略我们可以给出什么。",
        "与其因成绩深受压力，更希望变成为寻梦而努力的学生。",
        "不要把你的好运都送给我，是我会把爱继续给你。", "我希望关于你的所有回答我都能排在第一。",
        "爱情真的很美好，谁都认为是理想的美好的，活着必须得经历一次至死不渝的爱情。",
        "第一个请跟我约定不会离开我身边，会跟我约定吗？", "第二个每天跟我说爱我，会跟我约定吗？",
        "别人的生活，你到底多有资格评价？", "你能做好吗？“我无条件都会做好的。”",
        "比起已经过去的时间，剩下的时间更长，我们一起走下去吧。",
        "只有做这个我仿佛才能活下去……只有做这个我才能获得更多力量，这首歌对我而言，如同绿洲。",
        "想做的事情大胆去做吧", "为了玩儿而努力工作，为了自由而遵守规则", "要做到120%才能呈60%-70%啊”"
    ]
    static func mode(for title: String) -> String {
        if ["锻炼", "运动", "健身", "跑步", "瑜伽", "哑铃", "俯卧撑"].contains(where: title.contains) { return "锻炼" }
        if ["学习", "读书", "阅读", "背单词", "复习", "课程", "作业", "论文", "编程"].contains(where: title.contains) { return "学习" }
        return "陪伴"
    }
    var displayActivity: String {
        if activity == "吃饭" || activity == "开心" || activity == "wink" { return activity }
        guard let session = data.session else { return activity }
        if session.started == nil { return "陪伴" }
        return session.mode == "锻炼" ? "健身" : session.mode == "学习" ? "学习" : "陪伴"
    }
    func petInteraction() {
        switch Int.random(in:0..<3) {
        case 0: act("wink", "给你一个 wink，今天也要有好心情！")
        case 1: act("开心", "摸摸头，能陪着你真好。")
        default: speech = "嗨，我在这儿呢。今天想一起做点什么？"
        }
    }
    func sayQuote() {
        var indices = Array(Self.quotes.indices); indices.removeAll { $0 == lastQuote }
        lastQuote = indices.randomElement() ?? 0; speech = Self.quotes[lastQuote]
        speechLockedUntil = Date().addingTimeInterval(max(12,Double(speech.count)*0.3))
    }
    func start(_ task: Todo, mode: String? = nil, now: Date = Date()) {
        guard data.session == nil, !task.done else { return }
        data.session = FocusSession(taskID: task.id, title: task.title, mode: mode ?? Self.mode(for: task.title), started: now)
        actionToken = UUID(); activity = "陪伴"
        speech = "我陪你一起\(data.session!.mode)，准备好就出发吧。"; save()
    }
    func pause(now: Date = Date()) {
        guard var session = data.session, session.started != nil else { return }
        session.accumulated = session.duration(at: now); session.started = nil; data.session = session
        speech = "休息一下，我在这里等你。"; save()
    }
    func resume(now: Date = Date()) {
        guard data.session != nil, data.session?.started == nil else { return }
        data.session?.started = now; speech = "继续吧，我陪着你。"; save()
    }
    func finish(now: Date = Date()) {
        guard let session = data.session else { return }
        let duration = session.duration(at: now)
        data.focusLogs = (data.focusLogs ?? []) + [FocusLog(task: session.title, mode: session.mode, seconds: duration, date: now)]
        data.session = nil; actionToken = UUID(); activity = "陪伴"
        speech = "我们一起\(session.mode)了\(durationText(duration))，辛苦啦！"; save()
    }
    init(file: URL? = nil) {
        self.file = file ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("TigerPet/data.json")
        do {
            if FileManager.default.fileExists(atPath: self.file.path) {
                data = try JSONDecoder().decode(Saved.self, from: Data(contentsOf: self.file))
            }
        } catch { saveError = "无法读取存档，已保留原文件：\(error.localizedDescription)" }
        quiet = data.quietSetting ?? false
        // Restore interrupted sessions paused; never count time while the app was closed.
        if data.session != nil { data.session?.started = nil }
    
    }
    func save() {
        // Never overwrite an unreadable existing save.
        guard saveError == nil else { return }
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(data).write(to: file, options: .atomic)
        } catch { saveError = "保存失败：\(error.localizedDescription)" }
    }
    func add(_ title: String, reward: Int) {
        let text = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        data.tasks.append(Todo(title: text, reward: reward, day: dayKey())); save()
    }
    func complete(_ id: UUID) {
        guard let i = data.tasks.firstIndex(where: { $0.id == id }), !data.tasks[i].done else { return }
        let wasFocusing = data.session?.taskID == id
        if wasFocusing { finish() }
        let summary = speech
        data.tasks[i].done = true; data.points += data.tasks[i].reward; save()
        act("开心", wasFocusing ? summary + "任务已完成，积分到账。" : "做得好！又完成了一件事。")
    }
    func buyFood(_ food: Food) {
        guard data.points >= food.price else { return }
        data.points -= food.price
        var pantry = data.pantry ?? [:]; pantry[food.id,default:0] += 1; data.pantry = pantry
        speech = "\(food.name)放进背包啦！"; save()
    }
    func feedFood(_ food: Food) {
        guard (data.pantry?[food.id] ?? 0) > 0 else { return }
        var pantry = data.pantry ?? [:]; pantry[food.id,default:0] -= 1; data.pantry = pantry
        eatingFood = food; data.affection = (data.affection ?? 0)+1; save()
        act("吃饭", "啊呜，\(food.name)真好吃！亲密度 +1")
    }
    func buy() {
        guard data.points >= 15 else { speech = "完成任务可以获得积分哦。"; return }
        data.points -= 15; data.meals += 1; save(); speech = "小饭团已放进背包！"
    }
    func feed(free: Bool = false) {
        eatingFood = nil
        if !free {
            guard data.meals > 0 else { speech = "背包空啦，也可以领一份免费口粮。"; return }
            data.meals -= 1; save()
        }
        data.affection = (data.affection ?? 0) + 1; save()
        act("吃饭", "啊呜，谢谢你的照顾！亲密度 +1")
    }
    var canSpeakAutomatically: Bool { Date() >= speechLockedUntil }
    func act(_ name: String, _ message: String) {
        let token = UUID(); actionToken = token; activity = name; actionStarted = Date(); speech = message
        if name != "睡觉" {
            DispatchQueue.main.asyncAfter(deadline: .now() + (name == "wink" ? 1.2 : 6)) { [weak self] in
                guard let self, self.actionToken == token else { return }; self.activity = "陪伴"
            }
        }
    }
}

func durationText(_ seconds: Double) -> String {
    let value = max(0, Int(seconds))
    return value >= 3600 ? "\(value / 3600)小时\(value % 3600 / 60)分\(value % 60)秒" : "\(value / 60)分\(value % 60)秒"
}
// Cache atlas crops once. Alpha is preserved; no image decoding during animation ticks.
enum PlushAssets {
    static var cache: [String: NSImage] = [:]
    static func image(_ name: String, column: Int = 0, row: Int = 0, columns: Int = 1, rows: Int = 1) -> NSImage? {
        let key = "\(name)-\(column)-\(row)"
        if let value = cache[key] { return value }
        let root = Bundle.main.resourceURL?.appendingPathComponent("Assets")
        let local = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Assets")
        guard let image = NSImage(contentsOf: (root?.appendingPathComponent(name)).flatMap { FileManager.default.fileExists(atPath:$0.path) ? $0 : nil } ?? local.appendingPathComponent(name)),
              let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let w = cg.width / columns, cellHeight = cg.height / rows
        // The concept atlas has uneven vertical whitespace; exclude the next row's ears.
        let h = rows == 2 && row == 0 ? Int(Double(cg.height)*0.44) : cellHeight
        guard let crop = cg.cropping(to: CGRect(x: column*w, y: row*cellHeight, width:w, height:h)) else { return nil }
        let result = NSImage(cgImage: crop, size: NSSize(width:w,height:h)); cache[key] = result
        return result
    }
}
struct Tiger: View {
    var activity: String
    var phase: Double
    var facing: Double = 1
    var elapsed: Double = 0
    var food: Food? = nil
    var body: some View {
        let jumping = activity == "跳跃"
        let cycle = elapsed.truncatingRemainder(dividingBy: 1.8) / 1.8
        let flight = max(0, min(1, (cycle-0.18)/0.55))
        let lift = jumping && cycle > 0.18 && cycle < 0.73 ? sin(flight * .pi)*42 : 0
        let running = activity == "跑步"
        let sprite: NSImage? = {
            switch activity {
            case "wink": return PlushAssets.image("tiger-talents.png",column:2,columns:3)
            case "唱歌": return PlushAssets.image("tiger-talents.png",columns:3)
            case "写歌": return PlushAssets.image("tiger-talents.png",column:1,columns:3)
            case "跳舞": return PlushAssets.image("tiger-talents.png",column:2,columns:3)
            case "学习": return PlushAssets.image("tiger-focus.png", column: Int(elapsed/90) % 2 + 1, columns: 3)
            case "健身": return PlushAssets.image("tiger-workout.png", column: Int(phase/0.85) % 2, columns:2)
            case "跑步": return PlushAssets.image("tiger-sprites.png", column: sin(phase*9) > 0 ? 0 : 1, columns: 3, rows: 2)
            case "跳跃": return PlushAssets.image("tiger-sprites.png", column: lift > 5 ? 2 : 0, columns: 3, rows: 2)
            case "睡觉": return PlushAssets.image("tiger-sprites.png", row: 1, columns: 3, rows: 2)
            case "吃饭": return PlushAssets.image("tiger-feeding.png",column:elapsed < 1.5 ? 0 : 1,columns:2)
            case "伸展", "开心": return PlushAssets.image("tiger-sprites.png", column: 2, row: 1, columns: 3, rows: 2)
            default: return PlushAssets.image("tiger-standing.png")
            }
        }()
        ZStack(alignment: .bottom) {
            if let sprite {
                Image(nsImage:sprite).resizable().interpolation(.high).scaledToFit()
                    .frame(width:220,height:activity == "跳跃" ? 175 : 220,alignment:.bottom)
                    .scaleEffect(x: running || jumping ? facing : 1, y: activity == "健身" ? 1+sin(phase*3)*0.018 : 1, anchor:.bottom)
                    .rotationEffect(.degrees(activity == "跳舞" ? sin(phase*5)*7 : activity == "唱歌" ? sin(phase*3)*3 : 0),anchor:.bottom)
                    .offset(y:-lift + (running ? sin(phase*18)*3 : activity == "跳舞" ? -abs(sin(phase*5))*8 : 0))
            } else { Text("🐯").font(.system(size:100)) }
            if activity == "吃饭" {
                let food = food ?? Food(id:"rice",name:"饭团",emoji:"🍙",price:0)
                VStack(spacing:0) {
                    if food.hot { Text("♨︎").foregroundStyle(.white.opacity(0.85)).font(.title2).offset(y:-sin(phase*3)*4) }
                    Text(food.emoji).font(.system(size:40)).offset(y:sin(phase*4)*3)
                }.scaleEffect(elapsed > 4 ? 0.65 : 1).offset(y:elapsed < 1.5 ? -65 : -100)
            }
        }.frame(width:220,height:230,alignment:.bottom)
    }
}
struct FocusControls: View {
    @ObservedObject var store: Store
    var body: some View {
        if let session = store.data.session {
            VStack(alignment:.leading,spacing:6) {
                Text(session.title).lineLimit(1).font(.headline)
                TimelineView(.periodic(from:.now,by:1)) { context in
                    Text("\(session.mode) · \(durationText(session.duration(at:context.date)))\(session.started == nil ? " · 已暂停" : "")").monospacedDigit()
                }
                HStack {
                    Button(session.started == nil ? "继续" : "暂停") { session.started == nil ? store.resume() : store.pause() }
                    Button("结束计时") { store.finish() }
                }
            }.padding(10).background(.blue.opacity(0.08),in:RoundedRectangle(cornerRadius:12))
        }
    }
}

struct PetView: View {
    @ObservedObject var store: Store
    var open: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            Text(store.speech).font(.system(size: 12)).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true).help(store.speech)
                .padding(10).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14)).frame(width: 225)
            TimelineView(.animation(minimumInterval: store.quiet || store.reducedMotion || store.activity == "睡觉" ? 1 : 1.0/24)) { context in
                Tiger(activity: store.displayActivity, phase: context.date.timeIntervalSinceReferenceDate, facing: store.facing, elapsed: context.date.timeIntervalSince(store.actionStarted), food:store.eatingFood)
            }.gesture(DragGesture(minimumDistance: 4).onChanged { value in
                if let window = NSApp.windows.first(where: { $0 is PetWindow }) {
                    let point = NSEvent.mouseLocation
                    window.setFrameOrigin(NSPoint(x:point.x-value.startLocation.x-25,y:point.y-125))
                }
            }).onTapGesture { store.petInteraction() }
            if store.data.session != nil { FocusControls(store:store).font(.caption).frame(width:240) }
            HStack(spacing: 14) {
                Button("任务", action: open)
                Button("语录") { store.sayQuote() }
                Button("跳跳") { store.act("跳跃", "伸个懒腰，一起动一动！") }
                Button(store.activity == "睡觉" ? "叫醒" : "睡觉") { store.act(store.activity == "睡觉" ? "陪伴" : "睡觉", "我就在这里陪你。") }
            }.buttonStyle(.borderless).font(.system(size: 12)).padding(9).background(.regularMaterial, in: Capsule())
        }.padding(10).contextMenu {
            Button("打开任务与复盘", action: open)
            Button("跑一跑") { store.act("跑步", "出发，巡视桌面！") }
            Button("唱歌 🎤") { store.act("唱歌", "拿起话筒，今天这首歌送给你！♪") }
            Button("写歌") { store.act("写歌", "把今天的小心情写进旋律里。") }
            Button("跳舞") { store.act("跳舞", "跟着节奏，一起动起来！") }
            Button("听小虎说") { store.sayQuote() }
            Button("健身") { store.act("健身", "一起活动一下肩膀吧！") }
            Toggle("安静陪伴", isOn: $store.quiet)
            Button("退出") { NSApp.terminate(nil) }
        }
    }
}

struct Dashboard: View {
    @ObservedObject var store: Store
    @State private var title = ""
    @State private var reward = 15
    @State private var date = Date()
    @State private var mood = "平静"
    @State private var learning = ""
    @State private var note = ""
    @State private var saved = false
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("小虎的陪伴日记").font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("做一点喜欢的事，留一点时间给自己。").foregroundStyle(.secondary)
                }
                Spacer()
                Text("✦ \(store.data.points) 积分").font(.headline).padding(12).background(.yellow.opacity(0.2), in: Capsule())
            }
            if let error = store.saveError { Text(error).foregroundStyle(.red).textSelection(.enabled) }
            TabView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        TextField("添加一件想做的事…", text: $title).onSubmit(add)
                        Picker("奖励", selection: $reward) { ForEach([5, 15, 25, 40], id: \.self) { Text("\($0) 分").tag($0) } }.frame(width: 130)
                        Button("添加", action: add).buttonStyle(.borderedProminent).disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    FocusControls(store:store)
                    Text("未完成的任务会保留，按自己的节奏来。").font(.caption).foregroundStyle(.secondary)
                    List {
                        ForEach(store.data.tasks.reversed()) { task in
                            HStack {
                                Button { store.complete(task.id) } label: { Image(systemName: task.done ? "checkmark.circle.fill" : "circle").foregroundStyle(task.done ? .green : .secondary) }.buttonStyle(.plain).disabled(task.done)
                                VStack(alignment: .leading) { Text(task.title).strikethrough(task.done); Text(task.day).font(.caption).foregroundStyle(.secondary) }
                                Spacer()
                                if !task.done {
                                    Menu("开始") {
                                        Button("自动识别 · \(Store.mode(for:task.title))") { store.start(task) }
                                        Button("学习陪伴") { store.start(task,mode:"学习") }
                                        Button("锻炼陪伴") { store.start(task,mode:"锻炼") }
                                        Button("普通陪伴") { store.start(task,mode:"陪伴") }
                                    }.disabled(store.data.session != nil)
                                }
                                Text("+\(task.reward)").foregroundStyle(.secondary)
                                Button { if store.data.session?.taskID == task.id { store.finish() }; store.data.tasks.removeAll { $0.id == task.id }; store.save() } label: { Image(systemName: "trash") }.buttonStyle(.borderless).help("删除任务（已获得的积分保留）")
                            }.padding(.vertical, 6)
                        }
                        if store.data.tasks.isEmpty { Text("还没有任务，先从一件小事开始吧。 ").foregroundStyle(.secondary).padding() }
                    }.listStyle(.inset)
                }.padding().tabItem { Label("任务", systemImage: "checklist") }
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("小虎食堂 · 亲密度 \(store.data.affection ?? 0)").font(.title2.bold())
                        LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible()),GridItem(.flexible())],spacing:12) {
                            ForEach(Food.menu) { food in
                                VStack(spacing:8) {
                                    Text(food.emoji).font(.system(size:36))
                                    Text(food.name).font(.headline)
                                    Text("\(food.price) 积分 · 库存 \(store.data.pantry?[food.id] ?? 0)").font(.caption).foregroundStyle(.secondary)
                                    HStack {
                                        Button("购买") { store.buyFood(food) }.disabled(store.data.points < food.price)
                                        Button("投喂") { store.feedFood(food) }.disabled((store.data.pantry?[food.id] ?? 0) == 0)
                                    }
                                }.padding(12).frame(maxWidth:.infinity).background(.orange.opacity(0.07),in:RoundedRectangle(cornerRadius:14))
                            }
                        }
                        HStack {
                            Button("免费基础口粮 🍙") { store.feed(free:true) }
                            if store.data.meals > 0 { Button("投喂旧背包饭团（\(store.data.meals)）") { store.feed() } }
                        }
                        Text("没有完成任务也没关系，小虎会一直好好陪着你。").foregroundStyle(.secondary)
                        HStack { Button("一起举哑铃") { store.act("健身", "来，活动一下！") }; Toggle("安静陪伴", isOn:$store.quiet) }
                        HStack {
                            Button("唱歌 🎤") { store.act("唱歌", "拿起话筒，今天这首歌送给你！♪") }
                            Button("写歌") { store.act("写歌", "把今天的小心情写进旋律里。") }
                            Button("跳舞") { store.act("跳舞", "跟着节奏，一起动起来！") }
                            Button("听小虎说") { store.sayQuote() }
                        }
                        Toggle("全屏时减少活动", isOn:Binding(get:{store.data.autoFullscreen ?? true},set:{store.data.autoFullscreen=$0;store.save()}))
                        Picker("自主活动间隔",selection:Binding(get:{store.data.activityInterval ?? 120},set:{store.data.activityInterval=$0;store.save()})) {
                            Text("关闭").tag(0); Text("2 分钟").tag(120); Text("5 分钟").tag(300); Text("10 分钟").tag(600)
                        }
                        Picker("日常话语间隔",selection:Binding(get:{store.data.quoteInterval ?? 300},set:{store.data.quoteInterval=$0;store.save()})) {
                            Text("关闭").tag(0); Text("5 分钟").tag(300); Text("10 分钟").tag(600); Text("30 分钟").tag(1800)
                        }
                    }.padding(20)
                }.tabItem { Label("照顾小虎", systemImage:"heart") }
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        DatePicker("回顾这一天", selection: $date, in: ...Date(), displayedComponents: .date).onChange(of: date) { _ in loadReflection() }
                        Text("今天的心情").font(.headline)
                        Picker("心情", selection: $mood) { ForEach(["开心", "平静", "疲惫", "低落", "焦虑", "复杂"], id: \.self) { Text($0) } }.pickerStyle(.segmented)
                        Text("今天有什么值得学习？").font(.headline)
                        TextEditor(text: $learning).frame(height: 90).border(.gray.opacity(0.2))
                        Text("想留给自己的话（可选）").font(.headline)
                        TextEditor(text: $note).frame(height: 65).border(.gray.opacity(0.2))
                        HStack {
                            Button("保存复盘") {
                                store.data.reflections[dayKey(date)] = Reflection(mood: mood, learning: learning, note: note)
                                store.save(); saved = store.saveError == nil
                                store.speech = "谢谢你和我分享今天，辛苦啦。"
                            }.buttonStyle(.borderedProminent)
                            if saved { Text("已保存 ♡").foregroundStyle(.green) }
                        }
                        Text("任何心情都可以被记录。选择日期可以查看或修改过去的复盘。").font(.caption).foregroundStyle(.secondary)
                    }.padding(20)
                }.tabItem { Label("每日复盘", systemImage: "book.closed") }
                List {
                    ForEach((store.data.focusLogs ?? []).reversed()) { log in
                        VStack(alignment:.leading) {
                            Text(log.task).font(.headline)
                            Text("\(dayKey(log.date)) · \(log.mode) · \(durationText(log.seconds))").foregroundStyle(.secondary)
                        }.padding(6)
                    }
                }.tabItem { Label("陪伴记录", systemImage:"clock") }
            }
        }.padding(24).frame(minWidth: 650, minHeight: 550).tint(Color(red: 0.24, green: 0.36, blue: 0.64)).onAppear(perform: loadReflection)
    }
    func add() { store.add(title, reward: reward); title = "" }
    func loadReflection() {
        let r = store.data.reflections[dayKey(date)] ?? Reflection()
        mood = r.mood; learning = r.learning; note = r.note; saved = false
    }
}

final class PetWindow: NSPanel {
    override var canBecomeKey: Bool { true }
}
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = Store()
    var pet: PetWindow!
    var dashboard: NSWindow!
    var status: NSStatusItem!
    var timer: Timer?
    var tick = 0
    var direction: CGFloat = 1
    var lastActivity = Date()
    var lastQuote = Date().addingTimeInterval(-280)
    var autoWake: Date?
    var firstQuote = true
    var launchedAt = Date()
    var lastCheckpoint = Date()
    var lastFullscreenCheck = Date.distantPast
    var fullscreenCached = false
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let frame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        pet = PetWindow(contentRect: NSRect(x: frame.maxX-300, y: frame.minY+15, width: 270, height: 520), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        pet.isOpaque = false; pet.backgroundColor = .clear; pet.hasShadow = false
        pet.level = .floating; pet.collectionBehavior = [.canJoinAllSpaces]
        pet.isMovableByWindowBackground = true; pet.isReleasedWhenClosed = false
        pet.contentView = NSHostingView(rootView: PetView(store: store, open: { [weak self] in self?.showDashboard() }))
        pet.orderFrontRegardless()
        dashboard = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 740, height: 620), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        dashboard.title = "小虎 · 任务与每日复盘"; dashboard.isReleasedWhenClosed = false
        dashboard.contentView = NSHostingView(rootView: Dashboard(store: store)); dashboard.center()
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "🐯"
        let menu = NSMenu()
        menu.addItem(withTitle: "任务与每日复盘", action: #selector(showDashboard), keyEquivalent: "") .target = self
        menu.addItem(withTitle: "显示 / 隐藏小虎", action: #selector(togglePet), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出小虎", action: #selector(quit), keyEquivalent: "q").target = self
        status.menu = menu
        NSWorkspace.shared.notificationCenter.addObserver(forName:NSWorkspace.willSleepNotification,object:nil,queue:.main) { [weak self] _ in self?.store.pause() }
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.step() }
    }
    @objc func showDashboard() { dashboard.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    @objc func togglePet() { pet.isVisible ? pet.orderOut(nil) : pet.orderFrontRegardless() }
    func applicationWillTerminate(_ notification: Notification) { store.pause(); store.save() }
    @objc func quit() { NSApp.terminate(nil) }
    func isOtherAppFullscreen() -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication, app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              let screen = pet.screen,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly,.excludeDesktopElements], kCGNullWindowID) as? [[String:Any]] else { return false }
        return windows.contains { info in
            guard (info[kCGWindowOwnerPID as String] as? Int) == Int(app.processIdentifier),
                  (info[kCGWindowLayer as String] as? Int) == 0,
                  let bounds = info[kCGWindowBounds as String] as? [String:CGFloat],
                  let width = bounds["Width"], let height = bounds["Height"] else { return false }
            return width >= screen.frame.width-2 && height >= screen.frame.height-2
        }
    }
    func step() {
        let now = Date()
        if let wake = autoWake, now >= wake {
            autoWake = nil
            if store.activity == "睡觉" { store.act("陪伴", "睡醒啦，继续陪你！") }
        }
        if now.timeIntervalSince(lastCheckpoint) > 10 {
            if var session = store.data.session, session.started != nil {
                session.accumulated = session.duration(at: now); session.started = now; store.data.session = session; store.save()
            }
            lastCheckpoint = now
        }
        if now.timeIntervalSince(lastFullscreenCheck) >= 2 {
            fullscreenCached = isOtherAppFullscreen(); lastFullscreenCheck = now
        }
        let fullscreen = (store.data.autoFullscreen ?? true) && fullscreenCached
        if store.reducedMotion != fullscreen { store.reducedMotion = fullscreen }
        pet.collectionBehavior = store.data.autoFullscreen ?? true ? [.canJoinAllSpaces] : [.canJoinAllSpaces, .fullScreenAuxiliary]
        guard pet.isVisible, !store.quiet, !fullscreen, store.activity != "睡觉", store.data.session == nil else { return }
        guard NSEvent.pressedMouseButtons == 0 else { return }
        let interval = store.data.activityInterval ?? 120
        if interval > 0 && now.timeIntervalSince(lastActivity) >= Double(interval) && store.activity == "陪伴" && store.canSpeakAutomatically {
            let action = ["跑步", "跳跃", "伸展", "睡觉", "唱歌", "写歌", "跳舞"].randomElement()!
            store.act(action, action == "睡觉" ? "打个盹儿，需要我时摸摸头。" : "活动一下，也陪你看看桌面。")
            if action == "睡觉" { autoWake = now.addingTimeInterval(60) }
            lastActivity = now
        }
        let quoteInterval = store.data.quoteInterval ?? 300
        if quoteInterval > 0 && (now.timeIntervalSince(lastQuote) >= Double(quoteInterval) || (firstQuote && now.timeIntervalSince(launchedAt) >= 20)) && store.activity == "陪伴" && store.canSpeakAutomatically {
            store.sayQuote(); firstQuote = false; lastQuote = now
        }
        guard store.activity == "跑步", let screen = pet.screen ?? NSScreen.main else { return }
        let bounds = screen.visibleFrame
        var p = pet.frame.origin; p.x += direction * 5
        if p.x < bounds.minX || p.x + pet.frame.width > bounds.maxX { direction *= -1; p.x = min(max(p.x, bounds.minX), bounds.maxX-pet.frame.width) }
        p.y = min(max(p.y, bounds.minY), bounds.maxY-pet.frame.height)
        store.facing = Double(direction)
        pet.setFrameOrigin(p)
    }
}

if CommandLine.arguments.contains("--preview") {
    MainActor.assumeIsolated {
    let view = HStack(spacing: 24) {
        ForEach(CommandLine.arguments.contains("--actions") ? ["跑步", "跳跃", "睡觉", "吃饭"] : ["陪伴", "学习", "健身"], id: \.self) { state in
            VStack { Tiger(activity: state, phase: 0.3, elapsed: 0.8); Text(state).foregroundStyle(.black) }.padding(16)
        }
    }.background(Color(red: 0.97, green: 0.95, blue: 0.90))
    let renderer = ImageRenderer(content: view); renderer.scale = 2
    if let image = renderer.cgImage {
        let bitmap = NSBitmapImageRep(cgImage: image)
        try! bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments.last!))
    }
    }
} else if CommandLine.arguments.contains("--self-test") {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("TigerPet-test-\(UUID().uuidString)/data.json")
    let s = Store(file: url)
    s.add("测试任务", reward: 25)
    let id = s.data.tasks[0].id
    s.complete(id); s.complete(id)
    precondition(s.data.points == 25, "奖励不能重复领取")
    s.buy(); precondition(s.data.points == 10 && s.data.meals == 1)
    s.buy(); precondition(s.data.points == 10, "余额不能为负")
    s.feed(); s.feed(); precondition(s.data.meals == 0)
    s.data.reflections["2026-11-08"] = Reflection(mood: "平静", learning: "一次做一件事", note: "")
    s.save()
    let reloaded = Store(file: url)
    precondition(reloaded.data.points == 10 && reloaded.data.tasks[0].done)
    precondition(reloaded.data.reflections["2026-11-08"]?.learning == "一次做一件事")
    precondition(Store.mode(for:"学习英语") == "学习")
    precondition(Store.mode(for:"锻炼身体") == "锻炼")
    s.add("学习英语", reward:15)
    let task = s.data.tasks.last!
    let start = Date(timeIntervalSince1970:1000)
    s.start(task,now:start)
    s.pause(now:start.addingTimeInterval(65))
    precondition(s.data.session!.duration(at:start.addingTimeInterval(500)) == 65)
    s.resume(now:start.addingTimeInterval(500))
    s.finish(now:start.addingTimeInterval(530))
    precondition(s.data.focusLogs!.last!.seconds == 95)
    precondition(!s.data.tasks.last!.done, "停止计时不能自动完成任务")
    precondition(s.speech.contains("1分35秒"))
    let previousPoints = s.data.points
    s.complete(task.id); s.complete(task.id)
    precondition(s.data.points == previousPoints + 15)
    s.data.points = 100
    let ramen = Food.menu.first { $0.id == "ramen" }!
    s.buyFood(ramen); s.buyFood(ramen)
    precondition(s.data.points == 40 && s.data.pantry?["ramen"] == 2)
    s.feedFood(ramen); s.feedFood(ramen); s.feedFood(ramen)
    precondition(s.data.pantry?["ramen"] == 0)
    let old = Data("{\"points\":8,\"meals\":0,\"tasks\":[],\"reflections\":{}}".utf8)
    precondition(try! JSONDecoder().decode(Saved.self,from:old).points == 8)
    s.start(Todo(title:"锻炼",reward:5,day:dayKey()),now:start)
    s.pause(now:start.addingTimeInterval(20))
    let restored = Store(file:url)
    precondition(restored.data.session?.started == nil)
    precondition(restored.data.session?.accumulated == 20)
    print("PASS: 积分幂等、余额、投喂、存档、旧存档兼容、任务识别、暂停继续、时长总结与重启恢复")
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
