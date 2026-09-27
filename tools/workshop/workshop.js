const $ = id => document.getElementById(id);
let defaults = {wizard:1,enemy:1,enemy_sizes:{},tree:1,bush:1,effect_settings:{},spell_size:1,projectile:1,particle:1,zoom:1.3875,variant:'pursuer',comparison:false,scenery:true};
const labels = {wizard:'Wizard',enemy:'Selected enemy',tree:'Trees',bush:'Bushes',spell_size:'This spell · size',projectile:'This spell · artwork',particle:'This effect · particles',zoom:'Camera zoom'};
let settings = structuredClone(defaults), catalog = [], ready = false, playing = true, revision = 'unknown', activeId = 'bolt';
const frame = document.querySelector('iframe');
function send(action, extras = {}) { if (ready) frame.contentWindow.workshopCommand(JSON.stringify({action,...extras})); }
function syncSizes() {for (const key of Object.keys(labels)) {$(key).value=settings[key];$(key+'-value').textContent=Number(settings[key]).toFixed(2)+'×';} $('variant').value=settings.variant;$('comparison').checked=settings.comparison;$('scenery').checked=settings.scenery;}
for (const [key,label] of Object.entries(labels)) {
  const row=document.createElement('div');row.className='size';
  row.innerHTML='<label for="'+key+'">'+label+'<output id="'+key+'-value">'+defaults[key].toFixed(2)+'×</output></label><input id="'+key+'" type="range" min="0.5" max="3" step="0.05" value="'+defaults[key]+'" disabled>';
  $('sizes').append(row);if(key==='zoom')$(key).step='0.0125';
  $(key).addEventListener('input',e=>{settings[key]=Number(e.target.value);if(key==='enemy')settings.enemy_sizes[settings.variant]=settings.enemy;if(['spell_size','projectile','particle'].includes(key))rememberEffect();syncSizes();send('settings',{values:{[key]:settings[key]}});});
}
function rememberEffect(){settings.effect_settings[activeId]={spell_size:settings.spell_size,projectile:settings.projectile,particle:settings.particle};}
function chooseEffect(id){activeId=id;for(const key of ['spell_size','projectile','particle'])settings[key]=settings.effect_settings[id]?.[key]??1;syncSizes();send('select',{id});}
function exportData(){const globalSettings=structuredClone(settings);for(const key of ['spell_size','projectile','particle'])delete globalSettings[key];return {schema:2,source_revision:revision,purpose:'visual-preview-only',effect:activeId,settings:globalSettings};}
function options(){const previous=$('effect').value,query=$('search').value.toLowerCase();$('effect').replaceChildren();for(const group of ['Spells','Particles']){const opt=document.createElement('optgroup');opt.label=group;for(const e of catalog.filter(e=>e.group===group&&(e.name+' '+e.id).toLowerCase().includes(query))){const o=document.createElement('option');o.value=e.id;o.textContent=e.name;opt.append(o)}if(opt.children.length)$('effect').append(opt)}if([...$('effect').options].some(o=>o.value===previous))$('effect').value=previous;else $('effect').selectedIndex=-1;$('status').textContent=$('effect').options.length?'Select an effect to replay it.':'No matching effects.';}
window.addEventListener('message',event=>{
  if(event.source!==frame.contentWindow||event.origin!==location.origin||event.data?.source!=='spellcast-workshop')return;
  const {kind,payload}=event.data;
  if(kind==='ready'){catalog=payload.catalog;settings=structuredClone(payload.settings);defaults=structuredClone(payload.settings);ready=true;options();$('effect').value='bolt';for(const [id,value] of Object.entries(payload.variants)){$('variant').add(new Option(value.name,id));}document.querySelectorAll('[disabled]').forEach(e=>e.disabled=false);syncSizes();$('status').textContent='Ready. These are the actual game effects.';}
  if(kind==='state'&&payload.id===activeId){frame.dataset.targetsHit=payload.targets_hit;frame.dataset.activeEffects=payload.active_effects;playing=payload.playing;$('play').textContent=playing?'Pause':'Play';$('clock').textContent=payload.busy?'Preparing…':payload.time.toFixed(2)+' / '+payload.duration.toFixed(2)+' s';$('title').textContent=catalog.find(e=>e.id===payload.id)?.name||'Bolt';}
});
$('effect').onchange=()=>chooseEffect($('effect').value);$('search').oninput=options;
$('variant').onchange=()=>{settings.variant=$('variant').value;settings.enemy=settings.enemy_sizes[settings.variant]??1;syncSizes();send('settings',{values:{variant:settings.variant}});};
for(const key of ['comparison','scenery'])$(key).onchange=()=>{settings[key]=$(key).checked;send('settings',{values:{[key]:settings[key]}});};
$('play').onclick=()=>send('play',{value:!playing});$('step').onclick=()=>send('step');$('replay').onclick=()=>send('replay');$('speed').onchange=()=>send('speed',{value:Number($('speed').value)});$('loop').onchange=()=>send('loop',{value:$('loop').checked});
$('reset').onclick=()=>{settings=structuredClone(defaults);syncSizes();send('settings',{values:settings});$('status').textContent='Sizes reset to the current game defaults.';};
$('export').onclick=()=>{const data=exportData();const url=URL.createObjectURL(new Blob([JSON.stringify(data,null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download='spellcast-visual-settings.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);$('status').textContent='Settings exported. Game files have not changed.';};
fetch('build.json').then(r=>r.json()).then(data=>revision=data.revision).catch(()=>{});
setTimeout(()=>{if(!ready)$('status').textContent='The renderer is still loading. If it cannot start, check WebGL support or use the native gallery link above.';},30000);
