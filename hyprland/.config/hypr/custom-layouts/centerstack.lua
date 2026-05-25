hl.layout.register("centerstack", {
    recalculate = function(ctx)
        local n = #ctx.targets

        if n == 0 then
            return
        end

        local area = ctx.area

        -- single window
        if n == 1 then
            ctx.targets[1]:place(area)
            return
        end

        local sideWidth = math.floor(area.w * 0.20)
        local centerWidth = area.w - (sideWidth * 2)

        local left = {}
        local right = {}

        -- split side windows
        for i = 2, n do
            if i % 2 == 0 then
                table.insert(left, ctx.targets[i])
            else
                table.insert(right, ctx.targets[i])
            end
        end

        -- center/main
        ctx.targets[1]:place({
            x = area.x + sideWidth,
            y = area.y,
            w = centerWidth,
            h = area.h
        })

        -- LEFT SIDE
        local leftCount = #left

        if leftCount > 0 then
            local h = math.floor(area.h / leftCount)

            for i, target in ipairs(left) do
                target:place({
                    x = area.x,
                    y = area.y + ((i - 1) * h),
                    w = sideWidth,
                    h = h
                })
            end
        end

        -- RIGHT SIDE
        local rightCount = #right

        if rightCount > 0 then
            local h = math.floor(area.h / rightCount)

            for i, target in ipairs(right) do
                target:place({
                    x = area.x + sideWidth + centerWidth,
                    y = area.y + ((i - 1) * h),
                    w = sideWidth,
                    h = h
                })
            end
        end
    end,
})
