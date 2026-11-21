FROM mcr.microsoft.com/dotnet/sdk:10.0 AS bien-dich
WORKDIR /nguon
COPY may-chu.csproj ./
RUN dotnet restore may-chu.csproj
COPY . ./
RUN dotnet publish may-chu.csproj --configuration Release --no-restore --output /ban-chay /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS chay
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
COPY --from=bien-dich --chown=app:app /ban-chay ./
RUN mkdir -p /app/kho-tep && chown app:app /app/kho-tep
USER app
EXPOSE 8080
ENTRYPOINT ["dotnet", "MayChu.dll"]
