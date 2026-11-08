const {app,BrowserWindow,ipcMain,screen,Menu,powerMonitor} = require('electron');
const fs=require('node:fs'),path=require('node:path');
const {fresh,change,duration}=require('./model.cjs');
const quotes=require('./quotes.json');
let pet,board,data,file,lastQuote=-1,activity='陪伴',speech='今天也一起慢慢来吧！',started=Date.now(),food=null,token=0,quoteHold=0,lastAuto=Date.now(),lastSay=Date.now(),launched=Date.now(),firstQuote=true,autoWake=0,direction=1,saveError='';
if(!app.requestSingleInstanceLock())app.quit();
function save(){if(saveError)return;try{fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file+'.tmp',JSON.stringify(data));fs.renameSync(file+'.tmp',file);}catch(e){saveError='保存失败：'+e.message;}}
function snapshot(){return {data,activity,speech,started,food,saveError};}
function send(){for(const w of [pet,board])if(w&&!w.isDestroyed())w.webContents.send('state',snapshot());}
function act(name,text){activity=name;started=Date.now();speech=text;const t=++token;send();if(name!=='睡觉')setTimeout(()=>{if(t===token){activity='陪伴';send();}},name==='wink'?1200:6000);}
function quote(){firstQuote=false;let i;do{i=Math.floor(Math.random()*quotes.length);}while(i===lastQuote&&quotes.length>1);lastQuote=i;speech=quotes[i];lastSay=Date.now();quoteHold=lastSay+Math.max(12000,speech.length*300);send();}
function create(){const area=screen.getPrimaryDisplay().workArea;const options={webPreferences:{preload:path.join(__dirname,'preload.cjs'),contextIsolation:true,nodeIntegration:false,sandbox:true}};
 pet=new BrowserWindow({...options,width:290,height:570,x:area.x+area.width-310,y:area.y+area.height-580,transparent:true,frame:false,resizable:false,alwaysOnTop:true,skipTaskbar:false,title:'小虎陪伴'});
 pet.loadFile(path.join(__dirname,'pet.html'));
 board=new BrowserWindow({...options,width:920,height:760,minWidth:720,minHeight:620,show:false,title:'小虎 · 任务与每日复盘',backgroundColor:'#faf7f0'});
 board.loadFile(path.join(__dirname,'dashboard.html'));board.on('close',e=>{if(!app.exiting){e.preventDefault();board.hide();}});
 for(const w of [pet,board]){w.webContents.setWindowOpenHandler(()=>({action:'deny'}));w.webContents.on('will-navigate',e=>e.preventDefault());w.webContents.on('did-finish-load',send);}
 pet.on('closed',()=>app.quit()); Menu.setApplicationMenu(null);
}
app.whenReady().then(()=>{
 file=path.join(app.getPath('userData'),'data.json');data=fresh();
 try{if(fs.existsSync(file)){const old=JSON.parse(fs.readFileSync(file,'utf8'));data={...data,...old,settings:{...data.settings,...old.settings}};}}catch(e){saveError='存档读取失败，原文件已保留：'+e.message;}
 if(data.session)data.session.started=null;
 create();powerMonitor.on('suspend',()=>{change(data,'pause');save();send();});
 let checkpoint=Date.now(),fullscreen=false,lastFullscreen=0;
 setInterval(()=>{
 const now=Date.now();
 if(autoWake&&now>=autoWake){autoWake=0;if(activity==='睡觉')act('陪伴','睡醒啦，继续陪着你！');}
 if(now-checkpoint>10000){if(data.session?.started!==null&&data.session){data.session.accumulated=duration(data.session,now);data.session.started=now;save();}checkpoint=now;}
 // Electron cannot inspect another application's Windows fullscreen without native integration.
 if(pet.isDestroyed()||data.settings.quiet||data.session||activity==='睡觉')return;
 if(data.settings.quoteInterval>0&&activity==='陪伴'&&(now-lastSay>data.settings.quoteInterval*1000||(firstQuote&&now-launched>20000))){quote();}
 if(now<quoteHold)return;
 if(data.settings.activityInterval>0&&now-lastAuto>data.settings.activityInterval*1000&&activity==='陪伴'){
 const choices=['跑步','跳跃','伸展','睡觉','唱歌','写歌','跳舞'];const a=choices[Math.floor(Math.random()*choices.length)];act(a,'活动一下，继续陪你。');lastAuto=now;if(a==='睡觉')autoWake=now+60000;
 }
 if(activity==='跑步'){
 const b=pet.getBounds(),a=screen.getDisplayMatching(b).workArea;
 if(b.x<=a.x||b.x+b.width>=a.x+a.width)direction*=-1;
 pet.setPosition(Math.max(a.x,Math.min(a.x+a.width-b.width,b.x+direction*4)),Math.max(a.y,Math.min(a.y+a.height-b.height,b.y)));pet.webContents.send('facing',direction);
 }
 },100);
});
ipcMain.handle('get',()=>snapshot());
ipcMain.handle('change',(e,type,p)=>{if(![pet?.webContents,board?.webContents].includes(e.sender))return;const result=change(data,type,p);if(result.speech)speech=result.speech;if(result.activity){activity=result.activity;started=Date.now();food=result.food;const t=++token;setTimeout(()=>{if(t===token){activity='陪伴';send();}},6000);}save();send();return snapshot();});
ipcMain.on('ui',(e,action)=>{if(![pet?.webContents,board?.webContents].includes(e.sender))return;
 if(action==='dashboard'){board.show();board.focus();}else if(action==='quit')app.quit();else if(action==='quote')quote();else if(action==='pet'){const r=Math.floor(Math.random()*3);act(r===0?'wink':'开心',r===0?'给你一个 wink，今天也要有好心情！':'摸摸头，我一直在这儿。');}
 else {const text={'唱歌':'拿起话筒，今天这首歌送给你！♪','写歌':'把今天的小心情写进旋律里。','跳舞':'跟着节奏，一起动起来！','健身':'一起举哑铃！','跳跃':'蹲一蹲，跳起来！','睡觉':'打个盹儿，需要我时摸摸头。','跑步':'巡视一下桌面～'};if(text[action])act(action,text[action]);}
});
app.on('before-quit',()=>{app.exiting=true;if(data){change(data,'pause');save();}});
app.on('second-instance',()=>{if(pet){pet.show();pet.focus();}});
