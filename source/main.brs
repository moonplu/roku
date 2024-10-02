sub Main()
    reg = CreateObject("roRegistrySection", "profile")
    if reg.Exists("primaryfeed") then
        url = reg.Read("primaryfeed")
    else
        url = "https://raw.githubusercontent.com/moonplu/me/main/index.m3u"
    end if

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    m.global = screen.getGlobalNode()

    m3uLinks = GetM3uLinks(url)
    
    if m3uLinks.Count() = 0 then
        print "No valid links found."
        return
    end if

    for each link in m3uLinks
        if IsUrlAccessible(link) then
            m.global.addFields({feedurl: link})
            print "Using URL: "; link
            exit for
        else
            print "Link is down: "; link
        end if
    end for

    scene = screen.CreateScene("MainScene")
    screen.show()

    while(true) 
        msg = wait(0, m.port)
        msgType = type(msg)
        print "msgTYPE >>>>>>>>"; type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    end while
end sub

function GetM3uLinks(m3uUrl as String) as Object
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetMessagePort(CreateObject("roMessagePort"))
    urlTransfer.SetUrl(m3uUrl)
    
    response = urlTransfer.AsyncGetToString()
    msg = wait(5, response.GetMessagePort())

    if type(msg) = "roUrlEvent" then
        if msg.GetResponseCode() = 200 then
            data = msg.GetString()
            return ParseM3u(data)
        end if
    end if
    return invalid
end function

function ParseM3u(m3uData as String) as Object
    links = []
    lines = Split(m3uData, Chr(10)) ' Split the data into lines
    for each line in lines
        if line <> "" and line.Find(".m3u8") >= 0 then
            links.Push(line.Trim())
        end if
    end for
    return links
end function

function IsUrlAccessible(url as String) as Boolean
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetMessagePort(CreateObject("roMessagePort"))
    urlTransfer.SetUrl(url)
    urlTransfer.SetRequest("GET")
    
    response = urlTransfer.AsyncGetToString()
    
    msg = wait(5, response.GetMessagePort()) ' wait for a response
    if type(msg) = "roUrlEvent" then
        if msg.GetResponseCode() = 200 then
            return true
        else
            return false
        end if
    end if
    return false ' default to false if we don't get a response
end function
