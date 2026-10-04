local P=DT.Providers
local spec={
    okokBanking={'GetAccount','AddMoney','RemoveMoney'},['Renewed-Banking']={'getAccountMoney','addAccountMoney','removeAccountMoney'},
    ['qb-banking']={'GetAccountBalance','AddMoney','RemoveMoney',true},fd_banking={'GetAccount','AddMoney','RemoveMoney',true},
    ['kartik-banking']={'GetAccountMoney','AddAccountMoney','RemoveAccountMoney',true},['tgg-banking']={'GetSocietyAccountMoney','AddSocietyMoney','RemoveSocietyMoney'},
    ['tgiann-bank']={'GetJobAccountBalance','AddJobMoney','RemoveJobMoney'},wasabi_banking={'GetAccountBalance','AddMoney','RemoveMoney'}
}
for _,definition in ipairs(DTEcosystemCatalog.banking.providers) do
    P.Register('banking',definition.resource,function(resource)
        local api={GetManagmentName=function() return resource end};local config=spec[resource]
        if config then
            function api.GetAccountMoney(account)
                if resource=='wasabi_banking' then return P.Export(resource,config[1],account,'society') end
                return P.Export(resource,config[1],account)
            end
            for i,method in ipairs({'AddAccountMoney','RemoveAccountMoney'}) do
                local index=i+1
                api[method]=function(account,amount,reason)
                    amount=tonumber(amount);if not amount or amount<=0 or amount~=amount or amount==math.huge then return false,'invalid_amount' end
                    if resource=='wasabi_banking' then return P.Export(resource,config[index],'society',account,amount) end
                    if config[4] then return P.Export(resource,config[index],account,amount,reason or 'DTlib') end
                    return P.Export(resource,config[index],account,amount)
                end
            end
        elseif resource=='DHS-BankingSim' then
            function api.GetAccountMoney(account)
                local rows=DT.Database.Query("SELECT id FROM business_accounts WHERE job_name = ? AND status = 'active' LIMIT 1",{account})
                return rows and rows[1] and P.Export(resource,'GetBusinessBalance',rows[1].id) or nil,'account_not_found'
            end
            for _,method in ipairs({'AddAccountMoney','RemoveAccountMoney'}) do
                local debit=method=='RemoveAccountMoney'
                api[method]=function(account,amount)
                    amount=tonumber(amount);if not amount or amount<=0 or amount==math.huge or amount~=amount then return false,'invalid_amount' end
                    local sql="UPDATE business_accounts SET balance = balance "..(debit and '-' or '+').." ? WHERE job_name = ? AND status = 'active'"..(debit and ' AND balance >= ?' or '')
                    local args={amount,account};if debit then args[3]=amount end
                    return (DT.Database.Update(sql,args) or 0)>0
                end
            end
        end
        return api
    end)
end
