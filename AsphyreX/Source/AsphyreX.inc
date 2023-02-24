{.$HINTS OFF}
{.$WARNINGS OFF}

{ Enable the following option to support antialiased lines even when multisampling is disabled.
  This is typically supported on Nvidia DirectX hardware. }
{$DEFINE ANTIALIASEDLINES}

{$SCOPEDENUMS ON}
{$MINENUMSIZE 1}
{$B-}
{$I-}

{$ALIGN ON}

{$IFDEF NEXTGEN}
  {$ZEROBASEDSTRINGS OFF}
{$ENDIF}

{$EXCESSPRECISION OFF}

{$IFDEF POSIX}
  {$DEFINE FIREMONKEY}
{$ENDIF}
