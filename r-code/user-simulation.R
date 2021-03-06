source('./util/util.R')

remove.packages(nlme)
util$pkgRequire("nlme")
util$pkgRequire("maptools")
util$pkgRequire("evmix")
util$pkgRequire("doParallel")
library(doParallel)

MAX_ZOOM=20

dim(simulated.durations)

#cat(paste(simulated.durations[,1], collapse="\n"), file="/media/arquivos/Dropbox/mestrado/4-semestre/dissertacao/svnlabora/teses/msc/vinicius/texto/defesa/figs/r/muse-gm-durations.csv", append=F, sep="\n")
#cat(paste(simulated.durations[,2], collapse="\n"), file="/media/arquivos/Dropbox/mestrado/4-semestre/dissertacao/svnlabora/teses/msc/vinicius/texto/defesa/figs/r/muse-gm-number-of-actions.csv", append=F, sep="\n")

#cat(paste(simulated.durations[,1], collapse="\n"), file="/media/arquivos/Dropbox/mestrado/4-semestre/dissertacao/svnlabora/teses/msc/vinicius/texto/defesa/figs/r/muse-gm-durations-10min.csv", append=F, sep="\n")
#cat(paste(simulated.durations[,2], collapse="\n"), file="/media/arquivos/Dropbox/mestrado/4-semestre/dissertacao/svnlabora/teses/msc/vinicius/texto/defesa/figs/r/muse-gm-number-of-actions-10min.csv", append=F, sep="\n")

path = paste(PCLOUD_DIR, "mestrado/4-semestre/dissertacao/svnlabora/teses/msc/vinicius/texto/defesa/figs/resolutions/resolution-ww-monthly-201503-201505-bar.csv", sep="/");path
resolutions = read.table(path, sep=",", dec=".", header=TRUE);resolutions
resolutions = resolutions[-21,]
resolutions
#file.path = "/media/arquivos/Dropbox/mestrado/4-semestre/scala-scripts/data/actions4.csv"
file.path = paste(SIMULATED_DATA_PATH, "/actions-muse-gm-4950000-2.csv", sep="")

#plot(ecdf(simulated.intervals/1000), log="x", xlim=c(min(simulated.intervals)/1000, max(simulated.intervals)/1000))
#plot(ecdf(intervals), log="x", , xlim=c(min(simulated.intervals)/1000, max(simulated.intervals)/1000), col=2,add=T)

#cat("",file=file.path,append=FALSE)
op.dens.bkp <- op.dens
op.dens = op.dens[1:20,1:20];op.dens
sum(op.dens)
apply(op.dens, MARGIN=c(1), FUN=function(x) sum(x))
op.dens = op.dens/apply(op.dens, MARGIN=c(1), FUN=function(x) sum(x))
#op.dens <- op.dens.bkp
#op.dens <- op.dens.bkp10min
sum(op.dens[21,])

as.data.frame(op.dens)

registerDoParallel(16)

foreach(procnum=1:16) %dopar% {
  simulated.intervals <- c()
  simulated.durations <- data.frame(duration=c(), num.operations=c())
  simulated.zooms <- data.frame(last=c(), current=c(), x=c(), y=c())
  simulated.zooms.array <- c()
  simulated.zooms.jump <- c()
  simulated.pans <- data.frame(x=c(), y=c())
  simulated.number.of.operations <- c()
  
  print(paste("PROC =", procnum, sep=" "))
  
  file.path = paste(SIMULATED_DATA_PATH, "/musegen-original6-", procnum, ".csv", sep="")
  total.interval <- 0
  
  for (g in 1:10000000) {
    SIZE <- 10000
    
    freq.frame <- as.data.frame(op.dens)
    freq.frame
    
    lastOp <- ""
    lastZoom <- ""
    last.pan.dir <- ""
    last.zoom.dir <- ""
    
    #escolher primeiro passo
    (U <- runif(1))
    for (i in 1:length(operations.path$start.prob)) {
      probs.sorted <- sort(operations.path$start.prob)
      
      if (U < sum(probs.sorted[1:i])) {
        lastOp <- rownames(as.matrix(probs.sorted))[i]
        lastZoom <- lastOp
        break
      }
    }
    
    resolution <- choose.resolution()
  
    passos <- c(paste("SET_RESOLUTION(", resolution, ")", sep=""))
  
    initial.point <- choose.initial.original.point(lastZoom)
  
    start.interval <- simulate.interval()
  
    total.interval <- total.interval + start.interval
  
    passos <- c(passos, paste("START(", initial.point, ")+", start.interval, sep=""))
    num.ops = sample(op.per.access, 1)
  
    for (i in 1:num.ops) {
      probs <- freq.frame[as.numeric(lastOp),]
      probs.sorted <- sort(probs)
      
      U <- runif(1)    
      for (j in 1:length(probs.sorted)) {
        if (U < sum(probs.sorted[1:j])) {
          #path.synt <- c(path.synt, colnames(probs.sorted)[j])
          lastOp <- colnames(probs.sorted)[j]
          break
        }
      }
      if (lastOp == "start/end") {
        break
      } else {
        operation.sim <- simulate.operation(lastOp, lastZoom, last.pan.dir, last.zoom.dir)
        lastZoom <- lastOp
        passos <- c(passos, operation.sim)
      }
  #     if (total.interval > 1000 * 60 * 10) {
  #       print(paste("Total interval:", total.interval / (1000 * 60), "min", "NUM_OP:", length(passos), sep=" "))
  #       total.interval <- 0
  #       break
  #     }
    }
    passos <- c(passos)
    #print(passos, quote = FALSE)
  #  if (length(passos) > 3) {
    cat(paste(passos, collapse=";"), file=file.path, append=TRUE, sep="\n")
  #  } else {
  #    g <- g - 1
  #  }
  
    simulated.number.of.operations <- c(simulated.number.of.operations, length(passos))
    simulated.durations <- rbind(simulated.durations, data.frame(duration=total.interval, num.operations=length(passos)))
  
    #print(total.interval)
    #print(paste("Total interval:", total.interval / (1000 * 60), "min", "NUM_OP:", length(passos), sep=" "))
    total.interval <- 0
    #print(max(simulated.number.of.operations))
    print(g)
  }
}

# SUMMARY OF SIMULATED NUMBER OF OPERATIONS
length(simulated.number.of.operations)
summary(simulated.number.of.operations)

# SUMMARY OF SIMULATED SESSION DURATIONS
dim(simulated.durations)
summary(simulated.durations$duration/1000)
summary(simulated.durations$duration[simulated.durations$duration/1000 <= 24*60*60]/1000)

jumps.in.4 = as.numeric(as.character(simulated.zooms[as.character(simulated.zooms[,1]) == 15,2])) - 15
simulated.zooms
head(jumps.in.4)

head(simulated.zooms[as.numeric(as.character(simulated.zooms[,1])) == 15,2])

summary(jumps.in.4)

plot(table(jumps.in.4)/length(jumps.in.4), type="h")

# SUMMARY OF SIMULATED JUMPS SIZES
summary(simulated.zooms.jump)

table(simulated.zooms.jump)/length(simulated.zooms.jump)

jumpInZoom.simulated.freq <- 1:32 - 1:32

jumpInZoom.simulated.freq[30]
simulated.zooms.jump[simulated.zooms.jump == 16]

for (i in 1:length(simulated.zooms.jump)) {
  jumpSize <- simulated.zooms.jump[i] + 16
  if (jumpSize == 32) {
    print(jumpInZoom.simulated.freq[jumpSize])
  }
  jumpInZoom.simulated.freq[jumpSize] <- jumpInZoom.simulated.freq[jumpSize] + 1
}

jumpInZoom.simulated.freq

jumpInZoom.simulated.freq/sum(jumpInZoom.simulated.freq)

jumpInZoom.simulated.freq/sum(jumpInZoom.simulated.freq)

util$plot.eps("zoom-jump-size-mp", margin=c(3.6, 3.5, 1, 0.8))
plot(jumpInZoom.simulated.freq/sum(jumpInZoom.simulated.freq), type="h", log="y", lwd=13, col=c(2:16 - 1:15, 3:19 - 1:17), 
     xaxt="n", yaxt="n", xlab="Jump size", ylab="Frequency")
legend("topright", legend = c("Zoom Out", "Zoom In"),
       col = c(1, 2), pch=c(NA,NA), lty = c(1, 1),
       lwd=c(3,3),bty="n", cex=0.9)
axis(1, at=c(1, 5, 10, 15, 17, 21, 26, 31),labels=c(15, 10, 5, 1, 1, 5, 10, 15), col.axis="black", las=2)
axis(2, at=c(1e-4, 1e-3, 1e-2, 1e-1),labels=c("1e-04", "1e-03", "1e-02", "1e-01"), col.axis="black", las=3)
dev.off()

plot(density(simulated.intervals))
summary(simulated.number.of.operations)
summary(op.per.access)
quantile(simulated.number.of.operations, 0.8)
quantile(op.per.access, 0.8)
length(simulated.number.of.operations)

dim(simulated.durations)
summary(simulated.durations[,1]/1000)
summary(durations)

library(EnvStats)

#plot.eps("duration-model-simulated")
plot(ecdf(simulated.durations[,1]/1000), log="x", xlim=c(min(simulated.durations[,1]/1000), max(simulated.durations[,1]/1000)),
     ylab=expression("P(Duração da sessão " <= " x)"), xlab="Duração  da sessão (s)", main="", lw=3)
#dev.off()

plot(ecdf(simulated.durations[,1]/1000), log="x", xlim=c(min(simulated.durations[,1]/1000), max(simulated.durations[,1]/1000)))
lines(ecdf(durations[durations <= max(simulated.durations[,1]/1000)]), col=2)

#plot.eps("number-of-operations-model-simulated")
ecdfPlot(simulated.number.of.operations, ecdf.lty=1, ecdf.lw=6, ecdf.col=1, ylab=expression("P(Number of actions" <= " x)"), 
         xlab="Number of actions", main="")
#dev.off()

#SUMMARY OF PANS SIZES
summary(simulated.pans)

util$plot.eps("pan-size-model-simulated")
plot(density(simulated.pans$x), xlim=c(-1000, 1000), lwd=6, col=2, main="",
     xlab="Pan size (px)", ylab="Density", axes=F)
lines(density(simulated.pans$y), lty=2, lwd=6, col=4)

axis(side = 1, at=c(-1500, -1000, -500, 0, 500, 1000, 1500), labels=c(1500, 1000, 500, 0, 500, 1000, 1500))
axis(side = 2)
box()

arrows(0, 0, 0, 1, code = 2, col=1, lty=2, lwd=2)
arrows(-300, 0.002, -950, 0.002, length=0.25, angle = 30, code=2, col=2, lty=1, lwd=6)
arrows(-300, 0.0015, -950, 0.0015, length=0.25, angle = 30, code=2, col=4, lty=1, lwd=6)
arrows(300, 0.002, 950, 0.002, length=0.25, angle = 30, code = 2, col=2, lty=1,lwd=6)
arrows(300, 0.0015, 950, 0.0015, length=0.25, angle = 30, code = 2, col=4, lty=1,lwd=6)

text(cex=1, x=-550, y=0.0022, labels="Left", xpd=TRUE)
text(cex=1, x=-550, y=0.0017, labels="Upward", xpd=TRUE)
text(cex=1, x=550, y=0.0022, labels="Right", xpd=TRUE)
text(cex=1, x=550, y=0.0017, labels="Downward", xpd=TRUE)

legend("topright", legend = c("X", "Y"),
       col = c("red", "blue"), pch=c(NA,NA), lty=c(1, 2), lwd=c(4, 4),
       pt.cex=2, bty="n")
dev.off()

plot(density(simulated.zooms$x), xlim=c(-500, 500))
lines(density(simulated.zooms$y), col=2)

op.dens

simulated.zooms.all <- c(simulated.zooms$last, simulated.zooms$current) 
simulated.zooms.all <- factor(simulated.zooms.all, levels=1:nlevels(simulated.zooms$last), labels=levels(simulated.zooms$last))

#sample.zoom <- sample(simulated.zooms.array, 1000)

util$plot.eps("zoom-level-model-simulatation-2", margin=c(3, 3, 1, 0))
bp <- barplot(table(simulated.zooms.array) / length(simulated.zooms.array), ylim=c(0, 0.25), 
              names.arg="", xlab="Zoom level", ylab="Frequency",
              col=c("red"), mgp=c(2,0.5,.5))
text(cex=0.8, x=bp, y=-0.009, labels=levels(as.factor(simulated.zooms.array)), srt=-90, xpd=TRUE)
dev.off()

summary(simulated.zooms$current)

simulate.operation <- function(lastOp, lastZoom, last.pan.dir, last.zoom.dir) {
  interval <- simulate.interval() 
  simulated.zooms.array <<- c(simulated.zooms.array, as.numeric(lastOp))
  if (lastOp != lastZoom) {
    simulated.zooms.jump <<- c(simulated.zooms.jump, as.numeric(lastOp) - as.numeric(lastZoom))
    return(paste(simulate.zoom(lastZoom, lastOp, last.zoom.dir), "+", interval, sep=""))
  } else {
    return(paste(simulate.pan(lastOp, last.pan.dir), "+", interval, sep=""))
  }
}

all.directions.freq

first.pan.probs <- all.directions.freq[9,]
simulate.pan <- function(zoom.level, last.dir, result=c()) {
  parameter.x <- -0.0001376 * as.numeric(zoom.level) + 0.0079955
  parameter.y <- -0.0002038* as.numeric(zoom.level) + 0.0085857
  
  pan.x <- rgeom(1, parameter.x)
  pan.y <- rgeom(1, parameter.y)
  
  freq.frame <- as.data.frame(all.directions.freq)  
  
  if (last.dir == "") {
    last.dir <- sortear(first.pan.probs, last.dir)
  } else {
    probs <- freq.frame[last.dir,]
    last.dir <- sortear(probs, last.dir)
  }
  
  result <- c()
  if (last.dir == "0/PB") {
    result <- (c(0, pan.y))
  } else if (last.dir == "0/PC") {
    result <- (c(0, -pan.y))
  } else if (last.dir == "D/0") {
    result <- (c(pan.x, 0))
  } else if (last.dir == "D/PB") {
    result <- (c(pan.x, pan.y))
  } else if (last.dir == "D/PC") {
    result <- (c(pan.x, -pan.y))
  } else if (last.dir == "E/0") {
    result <- (c(-pan.x, 0))
  } else if (last.dir == "E/PB") {
    result <- (c(-pan.x, pan.y))
  } else if (last.dir == "E/PC") {
    result <- (c(-pan.x, -pan.y))
  }
  
  simulated.pans <<- rbind(simulated.pans, data.frame(x=result[1], y=result[2]))
  
  paste("PAN(", result[1], ",", result[2],")", sep="")
}

# O código abaixo utiliza os dados reais dos tamanhos dos arrastes
# simulate.pan <- function(zoom.level, last.dir, result=c()) {
#   moves.in.zoom = movesInPixels.readed[movesInPixels.readed[,3] == as.integer(zoom.level),]
#   U = floor(runif(1, 1, nrow(movesInPixels.readed) + 1))
#   pan.x <- abs(movesInPixels.readed[U,1])
#   pan.y <- abs(movesInPixels.readed[U,2])
# 
#   freq.frame <- as.data.frame(all.directions.freq)
# 
#   if (last.dir == "") {
#     last.dir <- sortear(first.pan.probs, last.dir)
#   } else {
#     probs <- freq.frame[last.dir,]
#     last.dir <- sortear(probs, last.dir)
#   }
# 
#   result <- c()
#   if (last.dir == "0/PB") {
#     result <- (c(0, pan.y))
#   } else if (last.dir == "0/PC") {
#     result <- (c(0, -pan.y))
#   } else if (last.dir == "D/0") {
#     result <- (c(pan.x, 0))
#   } else if (last.dir == "D/PB") {
#     result <- (c(pan.x, pan.y))
#   } else if (last.dir == "D/PC") {
#     result <- (c(pan.x, -pan.y))
#   } else if (last.dir == "E/0") {
#     result <- (c(-pan.x, 0))
#   } else if (last.dir == "E/PB") {
#     result <- (c(-pan.x, pan.y))
#   } else if (last.dir == "E/PC") {
#     result <- (c(-pan.x, -pan.y))
#   }
# 
#   simulated.pans <<- rbind(simulated.pans, data.frame(x=result[1], y=result[2]))
# 
#   paste("PAN(", result[1], ",", result[2],")", sep="")
# }

first.zoom.probs <- all.directions.z.freq[10,]
simulate.zoom <- function(last.zoom, current.zoom, last.dir, result=c()) {
  
  pan.x <- rgeom(1, fit.geo.x$estimate[1])
  pan.y <- rgeom(1, fit.geo.y$estimate[1])
  
  freq.frame <- as.data.frame(all.directions.z.freq)  
  
  if (last.dir == "") {
    last.dir <- sortear(first.zoom.probs, last.dir)
  } else {
    probs <- freq.frame[last.dir,]
    last.dir <- sortear(probs, last.dir)
  }
  
  result <- c()
  if (last.dir == "0/PB") {
    result <- (c(0, pan.y))
  } else if (last.dir == "0/PC") {
    result <- (c(0, -pan.y))
  } else if (last.dir == "D/0") {
    result <- (c(pan.x, 0))
  } else if (last.dir == "D/PB") {
    result <- (c(pan.x, pan.y))
  } else if (last.dir == "D/PC") {
    result <- (c(pan.x, -pan.y))
  } else if (last.dir == "E/0") {
    result <- (c(-pan.x, 0))
  } else if (last.dir == "E/PB") {
    result <- (c(-pan.x, pan.y))
  } else if (last.dir == "E/PC") {
    result <- (c(-pan.x, -pan.y))
  } else if (last.dir == "0/0") {
    result <- (c(0, 0))
  }
  
  simulated.zooms <<- rbind(simulated.zooms, data.frame(last=last.zoom, current=current.zoom, x=result[1], y=result[2]))
  
  paste("ZOOM(", last.zoom, "," ,current.zoom, "," ,result[1], ",", result[2],")", sep="")
}

sortear <- function(probs, result) {
  (U <- runif(1))
  for (i in 1:length(probs)) {
    probs.sorted <- sort(probs)
    
    if (U < sum(probs.sorted[1:i])) {
      result <- rownames(as.matrix(probs.sorted))[i]
      break
    }
  }
  result
}

summary(abs(rghyp(10000, ghyp(lambda=-0.7832549, alpha.bar=0.2383204, mu=0.3217918, sigma=0.7165768, gamma=5.8888598))))
summary(rlognormgpdcon(n=10000, lnmean=lngpd.fit$lnmean, lnsd=lngpd.fit$lnsd, u=lngpd.fit$u, 
                       xi=lngpd.fit$xi, phiu=lngpd.fit$phiu))

simulate.interval <- function() {
  #interval <- abs(rghyp(1, ghyp(lambda=-0.7832549, alpha.bar=0.2383204, mu=0.3217918, sigma=0.7165768, gamma=5.8888598)))
  interval <- rlognormgpdcon(n=1, lnmean=lngpd.fit$lnmean, lnsd=lngpd.fit$lnsd, u=lngpd.fit$u, 
                             xi=lngpd.fit$xi, phiu=lngpd.fit$phiu)
#   while (interval >  10 * 60) {
#     interval <- sample(intervals, 1)
#   }
  #interval <- rlnorm(1, 0.4983022, 0.5702684)
  total.interval <<- total.interval + as.integer(interval * 1000)
  simulated.intervals <<- c(simulated.intervals, as.integer(interval * 1000))
  as.integer(interval * 1000)
}

choose.resolution <- function() {
  probs <- resolutions[-21,2]/(sum(resolutions[-21,2]))
  probs.sorted <- sort(probs)
  
  resolution <- ""
  U <- runif(1)    

  for (j in 1:length(probs.sorted)) {
    if (U < sum(probs.sorted[1:j])) {
      resolution <- as.character(resolutions[abs(j - 20) + 1, 1])
      if (resolution == "") {
        print(paste("J = ", j, " e abs(j - 21) = ", abs(j - 21)))
      }
      break
    }
  }
  resolution
}

places.shape = important.cities$generate.places()
places <- as.data.frame(places.shape)
places <- places[with(places, order(POP2000)),]
probs.places <- places$POP2000/(sum(places$POP2000))
probs.places.sorted <- sort(probs.places)
head(places)

original_places_path = paste(PCLOUD_DIR, "/mestrado/publicacao/peval16/peval16/vinicius/data/coordinates.csv", sep="")
original_places = read.csv(original_places_path, header = F, sep=";");head(original_places)

choose.initial.original.point <- function(zoom) {
  coordinate <- ""
  
  places.by.zoom = original_places[original_places[,3] == as.integer(zoom),]
  
  U <- as.integer(runif(1, 1, nrow(places.by.zoom)))
  
  choosed.place = places.by.zoom[U, c(1,2,3)]
  coordinate <- paste(choosed.place[1], ",", choosed.place[2], ",", zoom, sep="")
  #cat(paste("new google.maps.LatLng(", coordinate, "),", sep=""), file="/media/arquivos/Dropbox/mestrado/4-semestre/gogeo/resultados-testes/50-users-coordinates.csv", append=TRUE, sep="\n")
  coordinate
}

choose.initial.point <- function(zoom) {
  coordinate <- ""
  
  U <- runif(1)    
  for (j in 1:length(probs.places.sorted)) {
    if (U < sum(probs.places.sorted[1:j])) {
      city <- places[j,]
      coordinate <- paste(city$coords.x2, ",", city$coords.x1, ",", zoom, sep="")
      break
    }
  }
  #cat(paste("new google.maps.LatLng(", coordinate, "),", sep=""), file="/media/arquivos/Dropbox/mestrado/4-semestre/gogeo/resultados-testes/50-users-coordinates.csv", append=TRUE, sep="\n")
  coordinate
}


for (i in 1:1000) {
  choose.initial.point(15)
}

print(choose.initial.point(15))

probs.initial.points <- points.per.polygon[,2]/(sum(points.per.polygon[,2]))
probs.initial.points.sorted <- sort(probs.initial.points)

choose.initial.point2 <- function(zoom) {  
  tile <- ""
  U <- runif(1)    
  for (j in 1:length(probs.initial.points.sorted)) {
    if (U < sum(probs.initial.points.sorted[1:j])) {
      tile <- as.character(points.per.polygon[j,1])
      break
    }
  }
  tile.to.coord(tile, zoom)
}

tile.to.coord = function(tile, zoom) {
  tile.splited <- (strsplit(tile, split="/", fixed=T))[[1]]
  
  c.z <- as.numeric(tile.splited[1])
  c.x <- as.numeric(tile.splited[2])
  c.y <- as.numeric(tile.splited[3])
  
  lat <- atan(sinh(pi - (c.y/2^c.z) * 2*pi)) * (180/pi)
  lon <- ((c.x/2^c.z) * 360) - 180
  
  initial.point <- paste(lat, lon, zoom, sep=",")
  initial.point
}
