const crypto = require('node:crypto');
const foods = [['tea','热奶茶','🧋',20,true],['coffee','美式','☕',15],['cake','小蛋糕','🍰',25],['ramen','热拉面','🍜',30,true],['egg','鸡蛋','🥚',5],['steak','牛排','🥩',40],['oatmilk','燕麦牛奶','🥛',15],['bento','盒饭','🍱',25],['dumpling','饺子','🥟',20],['strawberry','草莓','🍓',10],['blueberry','蓝莓','🫐',10],['avocado','牛油果','🥑',15],['seafood','海鲜','🦐',35],['sweetpotato','烤红薯','🍠',10,true],['chicken','鸡胸肉','🍗',20],['greens','绿叶菜','🥬',5]].map(([id,name,emoji,price,hot=false])=>({id,name,emoji,price,hot}));
function day() { const d=new Date(); return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`; }
function mode(title) { return /锻炼|运动|健身|跑步|瑜伽|哑铃|俯卧撑/.test(title)?'锻炼':/学习|读书|阅读|背单词|复习|课程|作业|论文|编程/.test(title)?'学习':'陪伴'; }
function duration(s, now=Date.now()) { return s ? s.accumulated + (s.started===null?0:Math.max(0,now-s.started)/1000) : 0; }
function durationText(seconds) { const n=Math.floor(seconds); return `${Math.floor(n/60)}分${n%60}秒`; }
function fresh() { return {points:0,meals:0,affection:0,tasks:[],pantry:{},reflections:{},focusLogs:[],session:null,settings:{quiet:false,activityInterval:120,quoteInterval:300,autoFullscreen:true}}; }
function change(d, type, p={}, now=Date.now()) {
 let speech=null, activity=null, food=null;
 const task=d.tasks.find(t=>t.id===p.id);
 const finish=()=>{const s=d.session;if(!s)return;const seconds=duration(s,now);d.focusLogs.push({id:crypto.randomUUID(),task:s.title,mode:s.mode,seconds,date:new Date(now).toISOString()});speech=`我们一起${s.mode}了${durationText(seconds)}，辛苦啦！`;d.session=null;};
 switch(type) {
 case 'add': { const title=String(p.title||'').trim().slice(0,200);if(title)d.tasks.push({id:crypto.randomUUID(),title,reward:[5,15,25,40].includes(p.reward)?p.reward:15,done:false,day:day()});break; }
 case 'complete': if(task&&!task.done){if(d.session?.taskID===task.id)finish();task.done=true;d.points+=task.reward;speech=(speech||'做得好！')+'任务已完成，积分到账。';activity='开心';}break;
 case 'delete': if(d.session?.taskID===p.id)finish();d.tasks=d.tasks.filter(t=>t.id!==p.id);break;
 case 'start': if(task&&!task.done&&!d.session){d.session={taskID:task.id,title:task.title,mode:['学习','锻炼','陪伴'].includes(p.mode)?p.mode:mode(task.title),accumulated:0,started:now};speech=`我陪你一起${d.session.mode}，出发吧！`;}break;
 case 'pause': if(d.session&&d.session.started!==null){d.session.accumulated=duration(d.session,now);d.session.started=null;speech='休息一下，我在这里等你。';}break;
 case 'resume': if(d.session&&d.session.started===null)d.session.started=now;break;
 case 'finish': finish();break;
 case 'buy': {const f=foods.find(f=>f.id===p.id);if(f&&d.points>=f.price){d.points-=f.price;d.pantry[f.id]=(d.pantry[f.id]||0)+1;speech=`${f.name}放进背包啦！`;}break;}
 case 'feed': {const f=foods.find(f=>f.id===p.id);if(p.free||(f&&d.pantry[f.id]>0)){if(!p.free)d.pantry[f.id]--;d.affection++;activity='吃饭';food=p.free?{emoji:'🍙',name:'饭团'}:f;speech=`啊呜，${food.name}真好吃！亲密度 +1`;}break;}
 case 'reflection': if(/^\d{4}-\d{2}-\d{2}$/.test(p.day)&&p.day<=day())d.reflections[p.day]={mood:String(p.mood||'平静'),learning:String(p.learning||'').slice(0,10000),note:String(p.note||'').slice(0,10000)};break;
 case 'settings': for(const key of ['quiet','autoFullscreen'])if(typeof p[key]==='boolean')d.settings[key]=p[key];for(const key of ['activityInterval','quoteInterval'])if([0,120,300,600,1800].includes(p[key]))d.settings[key]=p[key];break;
 }
 return {speech,activity,food};
}
module.exports={foods,day,mode,duration,durationText,fresh,change};
