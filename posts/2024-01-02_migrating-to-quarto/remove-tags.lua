-- If you want pandoc to remove all divs and delete all IDs from its org-mode output,
-- use pandoc's `--lua-filter` option and pass it the following lua script.
-- For more information see https://pandoc.org/lua-filters.html

function Header (elem)
  elem.identifier = ""
  return elem
end

function Div (elem)
  return elem.content
end
