local MessageWriter = class('MessageWriter')

function MessageWriter:__init()

end

function MessageWriter:write(text)
    if Config.debugMode then
        print(text)
    end
end

return MessageWriter