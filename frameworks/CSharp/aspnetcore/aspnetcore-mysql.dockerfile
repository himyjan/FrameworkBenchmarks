FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /app
COPY src/Platform .
RUN dotnet publish -c Release -o out /p:DatabaseProvider=MySqlConnector

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
ENV URLS http://+:8080
ENV DOTNET_GCDynamicAdaptationMode=0
ENV DOTNET_ReadyToRun=0
ENV DOTNET_HillClimbing_Disable=1

WORKDIR /app
COPY --from=build /app/out ./
COPY appsettings.mysql.json ./appsettings.json

EXPOSE 8080

ENTRYPOINT ["dotnet", "Platform.dll"]
