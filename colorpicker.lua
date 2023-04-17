-- class's resource's
Colorpicker = { };

-- screen's resource's
local screen = Vector2 (guiGetScreenSize ());

function isCursorOnElement (x, y, width, height)
    if not isCursorShowing () then
        return false;
    end

    local cursor = {getCursorPosition ()};
    local cursorx, cursory = (cursor[1] * screen.x), (cursor[2] * screen.y);

    return ((cursorx >= x and cursorx <= (x + width)) and (cursory >= y and cursory <= (y + height)));
end

-- instance's resource's
local instance = { };

instance.total = 0;

instance.hover = false;
instance.actual = false;
instance.events = false;

instance.elements = { };

instance.types = {
    ['full'] = 'assets/images/full.png';
    ['default'] = 'assets/images/default.png';
}

-- event's resource's
function onClick (button, state)
    if not instance.events then
        return false;
    end

    if button ~= 'left' then
        return false;
    end

    
    if state == 'up' then
        local self = instance.actual;
        
        if not self or type (self) ~= 'table' then
            return false;
        end

        if not self.settings.moving then
            return false;
        end

        instance.actual = false;
        self.settings.moving = false;

        return true;
    end

    if state == 'down' then
        if not instance.hover then
            return false;
        end

        instance.actual = instance.hover;
        instance.hover.settings.moving = true;

        return true;
    end

    return false;
end

-- method's resource's
function Colorpicker:render ()
    if self.animation and not (type (self.animation) ~= 'table') then
        self.animation.alpha = interpolateBetween (self.animation.from, 0, 0, self.animation.to, 0, 0, (getTickCount () - self.animation.tick) / self.animation.time, 'Linear');
    end

    if isCursorShowing () and self.settings.moving then
        local cursor = {getCursorPosition ()};
        local cursorx, cursory = (cursor[1] * screen.x), (cursor[2] * screen.y);

        local color = {dxGetPixelColor (self.pixels, (self.sizes[1] / self.width) * (self.cursorx - self.x), (self.sizes[2] / self.height) * (self.cursory - self.y))};

        self.cursorx, self.cursory = (cursorx <= self.x and self.x or cursorx >= (self.x + self.width - self.cursor.x) and (self.x + self.width - self.cursor.x) or cursorx), (cursory <= self.y and self.y or cursory >= (self.y + self.height - self.cursor.y) and (self.y + self.height - self.cursor.y) or cursory);
        self.settings.color[1], self.settings.color[2], self.settings.color[3] = color[1], color[2], color[3];

        if self.callback and not (type (self.callback) ~= 'function') then
            self.callback (self.settings.color);
        end
    elseif not isCursorShowing () and self.settings.moving then
        self.settings.moving = false;

        instance.actual = false;
    end

    if isCursorOnElement (self.x, self.y, self.width, self.height) then
        instance.hover = self;
    else
        if instance.hover and not (instance.hover ~= self) then
            instance.hover = false;
        end
    end

    dxDrawImage (self.x, self.y, self.width, self.height, instance.types[self.type], 0, 0, 0, tocolor (255, 255, 255, self.animation.alpha or 255), self.postGUI);
    dxDrawImage (self.cursorx, self.cursory, self.cursor.x, self.cursor.y, 'assets/images/cursor.png', 0, 0, 0, tocolor (255, 255, 255, self.animation.alpha or 255), self.postGUI);

    return true;
end

function Colorpicker:create (x, y, width, height, cursor, style, animation, callback, postGUI)
    local data = { };

    setmetatable (data, {__index = self, __mode = 'k'});

    data.x, data.y, data.width, data.height = x, y, width, height;
    data.type = instance.types[style] and style or 'default';

    data.file = File (instance.types[data.type]);

    data.pixels = dxConvertPixels (data.file:read (data.file.size), 'plain');
    data.sizes = {dxGetPixelsSize (data.pixels)};

    data.file:close ();

    data.bar = Vector2 (2, 23);
    data.cursor = cursor or Vector2 (10, 10);

    data.postGUI = postGUI or false;
    data.callback = callback or false;
    data.animation = animation or false;

    data.index = (instance.total + 1);

    data.cursorx, data.cursory = data.x + (data.width / 2), data.y + (data.height / 2);

    data.settings = {
        moving = false;

        color = {255, 255, 255, 255};
    };

    instance.total = (instance.total + 1);
    instance.elements[data.index] = data;

    if data.callback and not (type (data.callback) ~= 'function') then
        data.callback (data.settings.color);
    end

    if instance.total > 0 and not instance.events then
        addEventHandler ('onClientClick', root, onClick);

        instance.events = true;
    end

    return data;
end

function Colorpicker:destroy ()
    if instance.actual == self then
        instance.actual = false;
    end

    if instance.hover == self then
        instance.hover = false;
    end

    instance.total = instance.total - 1;
    instance.elements[self.index] = nil;

    if instance.total < 1 and instance.events then
        removeEventHandler ('onClientClick', root, onClick);

        instance.events = false;
    end

    return true;
end

function Colorpicker:getColor ()
    return self.settings.color;
end

function Colorpicker:setAnimation (animation)
    if not animation or type (animation) ~= 'table' then
        return false;
    end

    self.animation.from, self.animation.to = animation.from, animation.to;
    self.animation.tick = getTickCount ();

    return true;
end