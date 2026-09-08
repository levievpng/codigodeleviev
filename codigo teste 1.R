# ==============================================================================
# PASSO 3: DOWNLOAD E RECORTE DO CLIMA ATUAL E FUTURO (CMIP6)
# ==============================================================================

# 1. Instalação dos pacotes (descomente caso não os tenha)
# install.packages("geodata")
# install.packages("terra")

# 2. Carregamento dos pacotes
library(geodata) # Para baixar automaticamente os dados do WorldClim e CMIP6
library(terra)   # Para manipulação de dados raster (alta performance)

# 3. Preparação do polígono da Caatinga (ATUALIZADO)
caatinga_vetor <- vect(area_estudo)

#Correção 1
clima_atual_global <- terra::rast("caminho/para/seu/arquivo_climatico.tif")

# Transformação crucial de CRS: projetamos o polígono para o mesmo CRS do clima
# Essa linha resolve o aviso "[mask] CRS do not match"
caatinga_vetor <- project(caatinga_vetor, crs(clima_atual_global))

# Definimos um diretório temporário no seu computador para salvar os downloads
dir_clima <- tempdir()

# 4. Download do Clima Atual (WorldClim)
cat("Baixando as 19 variáveis bioclimáticas atuais...\n")
# Baixa as variáveis globais de clima atual na resolução de 2.5 minutos (aprox. 5x5 km).
clima_atual_global <- worldclim_global(var = "bio", res = 2.5, path = dir_clima)

# 5. Download do Clima Futuro (Projeções CMIP6)
cat("Baixando projeções climáticas futuras (CMIP6 - MIROC6 - SSP585)...\n")
# Baixa o clima projetado para 2081-2100 (~80 anos no futuro) num cenário de altas emissões.
clima_futuro_global <- cmip6_world(
  model = "MIROC6", 
  ssp = "585", 
  time = "2081-2100", 
  var = "bioc", 
  res = 2.5, 
  path = dir_clima
)

# 6. Recorte (Crop e Mask) para a extensão da Caatinga
cat("Aplicando a máscara da Caatinga aos dados raster...\n")
# O 'crop' corta um retângulo (bounding box) em volta da área, o que agiliza o processamento
clima_atual_recortado <- crop(clima_atual_global, caatinga_vetor)
clima_futuro_recortado <- crop(clima_futuro_global, caatinga_vetor)

# O 'mask' apara as bordas exatamente no limite complexo do polígono da Caatinga
clima_atual_caatinga <- mask(clima_atual_recortado, caatinga_vetor)
clima_futuro_caatinga <- mask(clima_futuro_recortado, caatinga_vetor)

# 7. Padronização dos nomes das camadas
# IMPORTANTE: Para projetarmos o modelo no futuro (Passo 5), as camadas do clima atual 
# e do clima futuro PRECISAM ter exatamente os mesmos nomes.
nomes_variaveis <- paste0("bio", 1:19)
names(clima_atual_caatinga) <- nomes_variaveis
names(clima_futuro_caatinga) <- nomes_variaveis

# 8. Conferência visual do resultado (Comparando a Temperatura Média Anual - BIO1)
# Vamos plotar o clima atual e o futuro lado a lado
par(mfrow = c(1, 2)) # Divide o painel de gráficos em 1 linha e 2 colunas

# Plota a BIO1 Atual
plot(clima_atual_caatinga[["bio1"]], main = "Temp. Atual (BIO1)", 
     col = terrain.colors(100), axes = FALSE)
plot(caatinga_vetor, add = TRUE, col = NA, border = "black") # Adiciona a linha de contorno

# Plota a BIO1 Futura (Observe como as cores mostram um aquecimento claro)
plot(clima_futuro_caatinga[["bio1"]], main = "Temp. Futura (SSP585)", 
     col = heat.colors(100), axes = FALSE)
plot(caatinga_vetor, add = TRUE, col = NA, border = "black")

par(mfrow = c(1, 1)) # Restaura o painel gráfico para 1 único plot