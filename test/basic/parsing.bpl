
var $glob: int;

procedure {:some_attr} some_proc(x: int)
requires true;
ensures true;
modifies $glob;
{
  return;
}
