within MicroPythonMCU.Internal;

impure function StringHash "Deterministic hash of a string (djb2 over the first 64 characters, padded with spaces) - derives a radio network id unique inside the model from the instance name of a Peripherals.Radio.RadioAir, see requirements.md decision Radios micro:bit. Impure only to silence the frontend (StringToCharCodes is an external function, assumed impure - same discipline as getInstanceName() in parameter bindings)"
  input String s;
  output Integer h "Hash in 1..2147483646 (never 0: a RadioAir with networkId = 0 means \"derive it from the name\")";
protected
  Integer codes[64] = Internal.StringToCharCodes(s, 64);
algorithm
  h := 5381;
  for i in 1:64 loop
    h := mod(h*33 + codes[i], 2147483647);
  end for;
  h := if h == 0 then 1 else h;
end StringHash;
