const {contextBridge,ipcRenderer}=require('electron');
contextBridge.exposeInMainWorld('tiger',{get:()=>ipcRenderer.invoke('get'),change:(type,p)=>ipcRenderer.invoke('change',type,p),ui:action=>ipcRenderer.send('ui',action),onState:fn=>ipcRenderer.on('state',(_e,s)=>fn(s)),onFacing:fn=>ipcRenderer.on('facing',(_e,d)=>fn(d))});
