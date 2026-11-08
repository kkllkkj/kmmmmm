const assert=require('node:assert/strict');const {fresh,change,duration,mode,foods}=require('./model.cjs');
const d=fresh();change(d,'add',{title:'学习英语',reward:25});const id=d.tasks[0].id;
assert.equal(mode('学习英语'),'学习');assert.equal(mode('锻炼身体'),'锻炼');
change(d,'start',{id},1000);change(d,'pause',{},66000);assert.equal(duration(d.session,999000),65);change(d,'resume',{},100000);change(d,'finish',{},130000);assert.equal(d.focusLogs[0].seconds,95);assert.equal(d.tasks[0].done,false);
change(d,'complete',{id});change(d,'complete',{id});assert.equal(d.points,25);change(d,'buy',{id:'egg'});assert.equal(d.points,20);assert.equal(d.pantry.egg,1);change(d,'feed',{id:'egg'});change(d,'feed',{id:'egg'});assert.equal(d.pantry.egg,0);assert.equal(d.affection,1);assert.equal(foods.length,16);change(d,'reflection',{day:'2026-01-01',mood:'平静',learning:'一次做一件事'});assert.equal(d.reflections['2026-01-01'].learning,'一次做一件事');console.log('PASS: Windows 任务、积分、库存、投喂、暂停计时、总结与复盘');
