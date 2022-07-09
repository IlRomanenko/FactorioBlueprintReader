local List = {}
List.mt = {__index = List}

function List.create(value)
    local list = {prev = nil, next = nil, value = value}
    list.next = list
    list.prev = list
    setmetatable(list, List.mt);
    return list
end

function List.append(root, next)
    if root == nil and getmetatable(next) == List.mt then
        return next
    end
    if getmetatable(root) ~= List.mt or getmetatable(next) ~= List.mt then
        assert(false, "Can't insert non List object")
    end
    next.next = root.next
    next.next.prev = next
    next.prev = root
    root.next = next
    return root
end

function List:remove()
    local next = self.next
    if self == next then
        return nil
    end
    next.prev = self.prev
    next.prev.next = next
    self.prev = nil
    self.next = nil
    return next
end

return List