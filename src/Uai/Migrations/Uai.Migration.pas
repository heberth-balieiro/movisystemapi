unit Asmuv.Migration;

interface

uses
  App.Config;

type
  TAsmuvMigration = class
  public
    class procedure Run(const ACfg: TAppDatabaseConfig); static;
  end;

implementation

{ TAsmuvMigration }

class procedure TAsmuvMigration.Run(const ACfg: TAppDatabaseConfig);
begin
  // Migrations do módulo ASMUV serão executadas aqui.
end;

end.
