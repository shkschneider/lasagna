-- (custom > love > math)
random = random or (love and love.math.random) or math.random
math.random = random
-- remember to seed!
