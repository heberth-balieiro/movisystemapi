unit Catalogo.Seeds;

interface

type
  TCatalogoSeeds = class
  public
    class procedure Run; static;
  end;

implementation

uses
  Database.Seed,
  Database.Seed.Planos,
  Database.Seed.Unidade,
  Database.Seed.Segmento;

{ TCatalogoSeeds }

class procedure TCatalogoSeeds.Run;
begin
  TDatabaseSeed.Run;
  TDatabaseSeedPlanos.Run;
  TDatabaseSeedUnidade.Run;
  TDatabaseSeedSegmento.Run;
end;

end.
