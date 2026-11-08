DT.FrameworkUtil = DT.FrameworkUtil or {}
local frameworkUtil = DT.FrameworkUtil

frameworkUtil.aliases = {
    qbx = 'qbx_core',
    qbox = 'qbx_core',
    qb = 'qb-core',
    qbcore = 'qb-core',
    esx = 'es_extended',
    ox = 'ox_core',
    oxcore = 'ox_core',
}

function frameworkUtil.normalizeGrade(grade)
    if type(grade) == 'table' then
        return tonumber(grade.level or grade.grade or grade.id or grade.value) or 0, grade.name or grade.label
    end
    return tonumber(grade) or 0, nil
end

function frameworkUtil.normalizeGroup(data, forcedName, forcedGrade)
    if not data and not forcedName then
        return nil
    end
    data = data or {}
    local grade, nestedName = frameworkUtil.normalizeGrade(forcedGrade ~= nil and forcedGrade or data.grade)
    return {
        name = forcedName or data.name or data.id,
        label = data.label or data.name or forcedName,
        grade = grade,
        gradeName = nestedName or data.grade_name or data.gradeName or data.grade_label,
        gradeLabel = data.grade_label or data.gradeLabel or nestedName,
        onduty = data.onduty ~= nil and data.onduty or data.onDuty,
        isboss = type(data.grade) == 'table' and data.grade.isboss or data.isboss,
        type = data.type,
    }
end

function frameworkUtil.filterMatch(groups, filter)
    if type(groups) ~= 'table' then
        return false
    end
    if type(filter) == 'string' then
        return groups[filter] ~= nil
    end
    if type(filter) ~= 'table' then
        return false
    end
    for key, requirement in pairs(filter) do
        if type(key) == 'number' then
            if groups[requirement] ~= nil then
                return true
            end
        else
            local grade = tonumber(groups[key])
            if grade and grade >= (tonumber(requirement) or 0) then
                return true
            end
        end
    end
    return false
end

function frameworkUtil.resourceVersion(resource)
    if not resource then
        return nil
    end
    return GetResourceMetadata(resource, 'version', 0)
end

function frameworkUtil.playerIdentifiers(source)
    local out = {}
    for index = 0, GetNumPlayerIdentifiers(source) - 1 do
        local identifier = GetPlayerIdentifier(source, index)
        local kind = identifier and identifier:match('^([^:]+):')
        if kind then
            out[kind] = identifier
        end
    end
    return out
end
