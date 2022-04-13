const fs = require('fs');

let rawdata = fs.readFileSync('./tovicci/import.json');
let tovicci = JSON.parse(rawdata)
const entityIds = {}
const modelsIds = {}
const sourceIds = {}
const entityGroups = {}
const ignore = element => {
    return !['table','database','view'].includes(element.Id)
}
tovicci.Sources.filter(ignore).forEach(source => {
    const oldId = source.Id
    source.Id = `tv${source.Id}`
    sourceIds[oldId] = source.Id
})
tovicci.Models.filter(ignore).forEach(model => {
    const oldId = model.Id
    model.Id = `tv${model.Id}`
    modelsIds[oldId] = model.Id
})
tovicci.Entities.filter(ignore).forEach(entity => {
    const oldId = entity.Id
    const parts = entity.Id.split('.')
    parts[parts.length-1] = `TV${parts[parts.length-1]}`
    entity.Id=parts.join('.')
    entityIds[oldId]=parts.join('.')
    entityGroups[entity.Group]=`tv${entity.Group}`
    entity.Group=`tv${entity.Group}`
    entity.ModelId=`tv${entity.Group}`
})
const types = Object.keys(tovicci).filter(k => !['$type','Entities', 'Models', 'Sources'].includes(k))
const ids = {}
types.forEach(k => {
    console.log(`Prepending to ${k}`)
    if (tovicci[k] instanceof Array) {
        tovicci[k].forEach(obj => {
            if (obj && obj.Id) {
                ids[obj.Id] = `tv${obj.Id}`
                obj.Id = `tv${obj.Id}`
            }
        })
    }
})
console.log(Object.keys(tovicci))
let op = JSON.stringify(tovicci, null,2)
Object.keys(entityIds).forEach(id => {
    op = op.replaceAll(`${id}`,`${entityIds[id]}`)
})
Object.keys(modelsIds).forEach(id => {
    op = op.replaceAll(`"ModelId": "${id}"`,`"ModelId": "${modelsIds[id]}"`)
    op = op.replaceAll(`"SourceId": "${id}"`,`"SourceId": "${modelsIds[id]}"`)
    op = op.replaceAll(`"LinkedTo": "${id}`,`"LinkedTo": "${modelsIds[id]}`)
    op = op.replaceAll(`"${id}"`,`"${modelsIds[id]}"`)
})
Object.keys(sourceIds).forEach(id => {
    op = op.replaceAll(`"LinkedTo": "${id}`,`"LinkedTo": "${sourceIds[id]}`)
    op = op.replaceAll(`"SourceId": "${id}"`,`"SourceId": "${sourceIds[id]}"`)
})
Object.keys(ids).forEach(id => {
    op = op.replaceAll(`"LinkedTo": "${id}`,`"LinkedTo": "${ids[id]}`)
})
Object.keys(entityGroups).forEach(id => {
    op = op.replaceAll(`entities.${id}.`,`entities.${entityGroups[id]}.`)

})
fs.writeFileSync("./tovicci/import.json", op);