const foodList=[['tea','热奶茶','🧋',20,true],['coffee','美式','☕',15],['cake','小蛋糕','🍰',25],['ramen','热拉面','🍜',30,true],['egg','鸡蛋','🥚',5],['steak','牛排','🥩',40],['oatmilk','燕麦牛奶','🥛',15],['bento','盒饭','🍱',25],['dumpling','饺子','🥟',20],['strawberry','草莓','🍓',10],['blueberry','蓝莓','🫐',10],['avocado','牛油果','🥑',15],['seafood','海鲜','🦐',35],['sweetpotato','烤红薯','🍠',10,true],['chicken','鸡胸肉','🍗',20],['greens','绿叶菜','🥬',5]].map(([id,name,emoji,price,hot])=>({id,name,emoji,price,hot}));
function timeText(s){const n=Math.max(0,Math.floor(s));return `${Math.floor(n/60)}分${n%60}秒`;}
function localDay(){const d=new Date();return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;}
function elapsed(s){return s?s.accumulated+(s.started===null?0:Math.max(0,Date.now()-s.started)/1000):0;}
function node(tag,text,cls){const e=document.createElement(tag);if(text!==undefined)e.textContent=text;if(cls)e.className=cls;return e;}
function button(text,fn){const e=node('button',text);e.onclick=fn;return e;}
