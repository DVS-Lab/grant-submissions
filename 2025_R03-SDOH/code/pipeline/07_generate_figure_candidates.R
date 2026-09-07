source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))
if (!requireNamespace("ggplot2",quietly=TRUE)) stop("Package 'ggplot2' is required.")
d <- read_private_csv("analysis-master.csv")
for(v in c("demo_gender","ses_thi","ses_edu")) d[[v]] <- factor(d[[v]])
d$age_c <- d$demo_yrs-mean(d$demo_yrs,na.rm=TRUE)
d$ecog_c <- d$ecog_total-mean(d$ecog_total,na.rm=TRUE)
d$mspss_c <- d$mspss_total-mean(d$mspss_total,na.rm=TRUE)
fig_dir <- file.path(derived_dir(),"figures")
dir.create(fig_dir,recursive=TRUE,showWarnings=FALSE)
# This directory contains generated derivatives only. Remove stale PNGs so the
# index and directory always describe the same reproducible 11-figure menu.
unlink(list.files(fig_dir,pattern="\\.png$",full.names=TRUE))
index <- list()
mode_value <- function(x) names(which.max(table(x)))[1]

base_grid <- function(dat,n=100L) data.frame(
  age_c=0,
  demo_gender=factor(mode_value(dat$demo_gender),levels=levels(d$demo_gender)),
  ses_thi=factor(mode_value(dat$ses_thi),levels=levels(d$ses_thi)),
  ses_edu=factor(mode_value(dat$ses_edu),levels=levels(d$ses_edu))
)[rep(1,n),,drop=FALSE]

save_main <- function(exposure,outcome,xlabel,ylabel,filename,title,classification) {
  vars <- c(exposure,outcome,"age_c","demo_gender","ses_thi","ses_edu")
  dat <- d[stats::complete.cases(d[vars]),]
  if(nrow(dat)<50L) return(FALSE)
  fit <- stats::lm(stats::as.formula(paste(outcome,"~",exposure,"+ age_c + demo_gender + ses_thi + ses_edu")),data=dat)
  grid <- base_grid(dat)
  grid[[exposure]] <- seq(stats::quantile(dat[[exposure]],.02),stats::quantile(dat[[exposure]],.98),length.out=nrow(grid))
  pred <- stats::predict(fit,newdata=grid,interval="confidence")
  grid$fit<-pred[,"fit"]; grid$lwr<-pred[,"lwr"]; grid$upr<-pred[,"upr"]
  p <- ggplot2::ggplot(dat,ggplot2::aes(x=.data[[exposure]],y=.data[[outcome]]))+
    ggplot2::geom_point(alpha=.16,size=1.15,color="#37657a")+
    ggplot2::geom_ribbon(data=grid,ggplot2::aes(x=.data[[exposure]],y=.data$fit,ymin=.data$lwr,ymax=.data$upr),inherit.aes=FALSE,fill="#d9a7b0",alpha=.45)+
    ggplot2::geom_line(data=grid,ggplot2::aes(x=.data[[exposure]],y=.data$fit),inherit.aes=FALSE,color="#8b1e3f",linewidth=1.05)+
    ggplot2::labs(x=xlabel,y=ylabel,title=title,subtitle=paste0("Adjusted prediction with 95% CI; N = ",nrow(dat)))+
    ggplot2::theme_minimal(base_size=12)+ggplot2::theme(plot.title=ggplot2::element_text(face="bold"))
  ggplot2::ggsave(file.path(fig_dir,filename),p,width=7,height=5,dpi=300)
  index[[length(index)+1L]] <<- list(filename=filename,title=title,model=deparse(stats::formula(fit)),N=nrow(dat),classification=classification,
    caveat="Cross-sectional current-ZIP association; prediction fixes age at its mean and categorical covariates at modal levels.")
  TRUE
}

save_interaction <- function(exposure,moderator,outcome,xlabel,moderator_label,ylabel,filename,title,classification) {
  vars <- c(exposure,moderator,outcome,"age_c","demo_gender","ses_thi","ses_edu")
  dat <- d[stats::complete.cases(d[vars]),]
  if(nrow(dat)<50L) return(FALSE)
  covar_tail <- if(moderator=="age_c") "demo_gender + ses_thi + ses_edu" else "age_c + demo_gender + ses_thi + ses_edu"
  fit <- stats::lm(stats::as.formula(paste(outcome,"~",exposure,"*",moderator,"+",covar_tail)),data=dat)
  moderator_values <- mean(dat[[moderator]])+c(-1,0,1)*stats::sd(dat[[moderator]])
  xseq <- seq(stats::quantile(dat[[exposure]],.02),stats::quantile(dat[[exposure]],.98),length.out=90)
  grid <- base_grid(dat,length(xseq)*3L)
  grid[[exposure]] <- rep(xseq,3)
  grid[[moderator]] <- rep(moderator_values,each=length(xseq))
  grid$moderator_level <- factor(rep(c("Lower (−1 SD)","Mean","Higher (+1 SD)"),each=length(xseq)),
    levels=c("Lower (−1 SD)","Mean","Higher (+1 SD)"))
  pred <- stats::predict(fit,newdata=grid,interval="confidence")
  grid$fit<-pred[,"fit"]; grid$lwr<-pred[,"lwr"]; grid$upr<-pred[,"upr"]
  p <- ggplot2::ggplot(grid,ggplot2::aes(x=.data[[exposure]],y=.data$fit,color=.data$moderator_level,fill=.data$moderator_level))+
    ggplot2::geom_ribbon(ggplot2::aes(ymin=.data$lwr,ymax=.data$upr),alpha=.12,color=NA)+
    ggplot2::geom_line(linewidth=1)+
    ggplot2::labs(x=xlabel,y=ylabel,color=moderator_label,fill=moderator_label,title=title,
      subtitle=paste0("Adjusted predictions at mean and ±1 SD; 95% CIs; N = ",nrow(dat)))+
    ggplot2::theme_minimal(base_size=12)+ggplot2::theme(plot.title=ggplot2::element_text(face="bold"),legend.position="bottom")
  ggplot2::ggsave(file.path(fig_dir,filename),p,width=7.3,height=5.2,dpi=300)
  index[[length(index)+1L]] <<- list(filename=filename,title=title,model=deparse(stats::formula(fit)),N=nrow(dat),classification=classification,
    caveat="Cross-sectional interaction; moderator values are descriptive and were prespecified, not chosen from p-values.")
  TRUE
}

save_main("z_pm25","ctb_mean","PM2.5 (standardized)","CTB mean (1–6)","01-pm25-ctb.png","Long-term PM2.5 and delayed-reward preference","PRIMARY GRANT-ALIGNED")
save_main("z_sdi","fevs_total","SDI (standardized)","FEVS total (0–18)","02-sdi-fevs.png","Social deprivation and financial vulnerability","PRIMARY GRANT-ALIGNED")
save_main("z_sdi","oafem_weighted_total","SDI (standardized)","Weighted OAFEM total (0–124)","03-sdi-oafem.png","Social deprivation and exploitation indicators","PRIMARY GRANT-ALIGNED")
save_main("z_economic_connectedness","fevs_total","Economic connectedness (standardized)","FEVS total (0–18)","04-economic-connectedness-fevs.png","Economic connectedness and financial vulnerability","PRIMARY GRANT-ALIGNED")
save_main("z_economic_connectedness","oafem_weighted_total","Economic connectedness (standardized)","Weighted OAFEM total (0–124)","05-economic-connectedness-oafem.png","Economic connectedness and exploitation indicators","PRIMARY GRANT-ALIGNED")
save_main("z_gini","fevs_total","ZCTA Gini (standardized)","FEVS total (0–18)","06-gini-fevs.png","Income inequality and financial vulnerability","PRIMARY GRANT-ALIGNED")
save_main("z_pm25","ecog_total","PM2.5 (standardized)","eCog mean (1–4)","07-pm25-ecog.png","Long-term PM2.5 and subjective cognitive difficulty","USEFUL SECONDARY")
save_main("z_sdi","susd_depression","SDI (standardized)","SUSD depression (0–21)","08-sdi-depression.png","Social deprivation and depressive symptoms","PRIMARY GRANT-ALIGNED")
save_interaction("z_sdi","age_c","fevs_total","SDI (standardized)","Age","Predicted FEVS","09-sdi-age-fevs.png","Age, social deprivation, and financial vulnerability","PRIMARY GRANT-ALIGNED")
save_interaction("z_sdi","ecog_c","oafem_weighted_total","SDI (standardized)","eCog","Predicted weighted OAFEM","10-sdi-ecog-oafem.png","Cognitive vulnerability within socially deprived contexts","PRIMARY GRANT-ALIGNED")
save_interaction("z_economic_connectedness","mspss_c","fevs_total","Economic connectedness (standardized)","MSPSS","Predicted FEVS","11-economic-connectedness-mspss-fevs.png","Social support across levels of economic connectedness","PRIMARY GRANT-ALIGNED")

lines <- c("# Private draft figure index","",
  "Eleven figures were selected from prespecified scientific questions, not from p-values. Files remain private.","")
for(x in index) lines <- c(lines,paste0("## `",x$filename,"`"),"",paste0("- Title: ",x$title),paste0("- Model: `",x$model,"`"),
  paste0("- N: ",x$N),paste0("- Classification: ",x$classification),paste0("- Caveat: ",x$caveat),"")
writeLines(lines,file.path(derived_dir(),"figure-index.md"))
cat("Generated ",length(index)," private draft figures.\n",sep="")
