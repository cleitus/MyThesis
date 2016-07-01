!----------------------------------------------------------------------------------------------------------
! MODULE: calc_elem
!
!> @author JL Tailhan
!> @author J. Goncalvez (version 1.0 - 2010)
!
!> @brief
!> Calculs élémentaires: rigidité, contraintes.
!----------------------------------------------------------------------------------------------------------
module calc_elem


contains


!------------------------------------------------------------------------------------------------------
!> @authors J. Goncalvez (version 1.0 - 2010)
!
!> @brief
!> Calcul et assemblage de la rigidite globale Kg et du vecteur residu global vres
!
!> @details
!> #### DESCRIPTION:
!>  Entree :\n
!>  - ie : numero de l'element\n
!>  - kloce : position des ddls locaux\n
!>  - vprel : proprietes elementaires\n
!>  - vdle : valeur de la solution aux ddls locaux\n\n
!>
!>  Sorties :\n
!>  - vke : matrice de rigidite elementaire\n
!>  - vre : vecteur residu elementaire\n
!------------------------------------------------------------------------------------------------------
subroutine elem_ke(vke,vre,ie,ndle,vprel,vdle)

    !**************************************************************************************
    !* DEFINITIONS
    !**************************************************************************************

    !--------------------------------------------------------------------------------------
    !--- Modules generaux
    use variables, only :   dime, varint, infele, ktypel, nomtype,&
    &                       vcont, vnoli, vrint, kcont, knoli, krint, calco, inict, idmax, &
    !    Pour gestion des elements libres
    &                       elemlibre
    use initialisation, only : init_mat, init_vec
    use lib_elem, only : elem_B
    use aiguillage, only : rupture
    use contraintes
    use math

    implicit none

    !--------------------------------------------------------------------------------------
    !--- Variables in/out
    real*8, intent(inout) :: vke(ndle,ndle), vre(ndle)
    real*8, intent(in) :: vprel(idmax), vdle(ndle)
    integer, intent(in) :: ie, ndle

    !--------------------------------------------------------------------------------------
    !--- Variables locales
    !integer, dimension(:,:), allocatable :: ksin
    real*8, dimension(:,:), allocatable :: ksig, vn, vb, vhep
    real*8, dimension(:,:), allocatable :: vsig0, vnle0, vsig, vnle, vint
    real*8, dimension(:), allocatable :: vsi0, vnl0, vsi, vnl, vin, vpg

    integer :: nc1, nc2, nc3, npg, idim1, idim2, idim3, iloc1, iloc2, iloc3, idm1, idm2, idm3
    integer :: ipg, id, ndln, nnel
    real*8 :: detj, wpla, wplael, poids, pdet, epais, rho, fvx, fvy, fvz, vfext(ndle), vfint(ndle)

    character(len=5) :: typel

    !**************************************************************************************
    !* CORPS DE PROCEDURE
    !**************************************************************************************

    !--------------------------------------------------------------------------------------
    !--- Recuperation de l'epaisseur (dime=2) et des forces de volume (dime=2 et 3)
    id = size(vprel)
    epais = 1.d0

    if (dime == 2) then
        if (int(vprel(2))==3) epais = vprel(id-2)  ! contraintes planes (CP)
        rho = vprel(3)
        fvx = vprel(id-1)
        fvy = vprel(id)
    elseif (dime == 3) then
        rho = vprel(3)
        fvx = vprel(id-2)
        fvy = vprel(id-1)
        fvz = vprel(id)
    else
        print*,' STOP: elem_ke: cas non implante'
        stop
    endif

    !--------------------------------------------------------------------------------------
    !--- Recuperation des informations sur les elements
    !allocate(ksin(size(infele(ktypel(ie))%ksin,1),size(infele(ktypel(ie))%ksin,2)))
    !ksin = infele(ktypel(ie))%ksin
    nnel = infele(ktypel(ie))%nnel
    ndln = infele(ktypel(ie))%ndln
    nc1  = infele(ktypel(ie))%ncgr     ! nombre de composantes du gradient
    nc2  = nc1 + 1                     ! nombre de composantes non lineaires
    nc3  = varint                      ! nombre de variables internes

    !--------------------------------------------------------------------------------------
    !--- Recuperation des points d'integration
    !allocate(vpg(size(infele(ktypel(ie))%W)))
    !allocate(ksig(size(infele(ktypel(ie))%Q,1),size(infele(ktypel(ie))%Q,2)))
    call init_vec(vpg, size(infele(ktypel(ie))%W))
    call init_mat(ksig,size(infele(ktypel(ie))%Q,1),size(infele(ktypel(ie))%Q,2))
    vpg  = infele(ktypel(ie))%W
    ksig = infele(ktypel(ie))%Q
    npg  = size(vpg)

    !--------------------------------------------------------------------------------------
    !--- initialisations vecteurs/matrices elementaires
    vke = 0.d0 ; vfint = 0.d0  ; vfext = 0.d0 ; vre = 0.d0

    !--------------------------------------------------------------------------------------
    !--- localisation des donnees elementaires dans les vecteurs globaux
    !       if (calco == 'NOEUD') then
    !           idim1 = nnel*nc1
    !           idim2 = nnel*nc2
    !           idim3 = nnel*nc3
    !       elseif (calco == 'GAUSS') then
    idim1 = npg*nc1
    idim2 = npg*nc2
    idim3 = npg*nc3
    !       endif
    iloc1 = kcont(ie)
    iloc2 = knoli(ie)
    iloc3 = krint(ie)
    idm1  = idim1/nc1
    idm2  = idim2/nc2
    idm3  = idim3/nc3

    !--------------------------------------------------------------------------------------
    !--- Recuperation des vecteurs elementaires dans vcont et vnoli
    !allocate(vsig0(nc1, idm1));  allocate(vnle0(nc2, idm2))
    !allocate(vint(nc3, idm3))

    call init_mat(vsig0, nc1, idm1)
    call init_mat(vnle0, nc2, idm2)
    call init_mat(vint , nc3, idm3)

    vsig0 = reshape(vcont(iloc1 : (iloc1 + idim1 - 1)), (/nc1, idm1/))
    vnle0 = reshape(vnoli(iloc2 : (iloc2 + idim2 - 1)), (/nc2, idm2/))
    vint  = reshape(vrint(iloc3 : (iloc3 + idim3 - 1)), (/nc3, idm3/))

    !--------------------------------------------------------------------------------------
    !--- Si calcul des contraintes aux noeuds
    if (calco == 'NOEUD') then

        !call init_mat(vsig, nc1, nnel); call init_mat(vnle, nc2, nnel)

        !do ino = 1, nnel
            !call init_vec(vsi0, size(vsig0(:,ino)))
            !call init_vec(vnl0, size(vnle0(:,ino)))
            !------- Calcul des fonctions d'interpolation et des derivees --
            !call elem_B(vn, vb, detj, DBLE(ksin(ino,:)), ie)
            !vsi0 = vsig0(:,ino)
            !vnl0 = vnle0(:,ino)
            !------- Calcul des contraintes en fonction du modele -----
            !call elem_sig(vsi,vnl,ie,vh,vb,vnl0, vprel, vdle)
            !vsig(:, ino) = vsi
            !vnle(1 : nc1, ino) = vnl(1:nc1)
            !wpla = vnl0(nc2) + .5*dot_product(vsi0+vsi,vnl(1:nc1)-vnl0(1:nc1))
            !vnle(nc2,ino) = wpla
            !deallocate(vsi0); deallocate(vnl0); deallocate(vn); deallocate(vb)
        !enddo

    else
        call init_mat(vsig, nc1, npg); call init_mat(vnle, nc2, npg)
    endif

    typel = nomtype(ktypel(ie))

    !--------------------------------------------------------------------------------------
    !--- Initialisation pour calcul de l'energie plastique
    wplael = 0.d0

    !--------------------------------------------------------------------------------------
    !--- Si calcul des contraintes aux points de Gauss pour integration et
    !      calcul du residu elementaire et de la matrice de masse
    do ipg = 1, npg
        poids = vpg(ipg)

        !----------------------------------------------------------------------------------
        !--- Calcul des fonctions d'interpolation et des derivees
        call elem_B(vn,vb,detj,ksig(ipg,:),ie)
        pdet = detj*poids*epais

        !----------------------------------------------------------------------------------
        !--- Partie de vre due au chargement volumique
        if ((typel=='BEA2').or.(typel=='BEF2').or.(typel=='BEF3')) then
            vfext(1:ndln*nnel:dime) = vfext(1:ndln*nnel:dime) + (rho*fvx*pdet)*vn(:,1)   !la charge q affecte (v,theta)
            vfext(2:ndln*nnel:dime) = vfext(1:ndln*nnel:dime) + (rho*fvx*pdet)*vn(:,1)   !la charge q affecte (v,theta)
            if (dime==3) then
                vfext(3:ndle:dime) = vfext(1:ndln*nnel:dime) + (rho*fvz*pdet)*vn(:,1)    !la charge q affecte (v,theta)
            endif
        else
            vfext(1:ndln*nnel:dime) = vfext(1:ndln*nnel:dime) + (rho*fvx*pdet)*vn(:,1)
            vfext(2:ndln*nnel:dime) = vfext(2:ndln*nnel:dime) + (rho*fvy*pdet)*vn(:,1)
            if (dime==3) then
                vfext(3:ndle:dime) = vfext(3:ndle:dime) + (rho*fvz*pdet)*vn(:,1)
            endif
        endif

        !----------------------------------------------------------------------------------
        !--- Recuperation (aux noeuds) ou calcul (aux PG) des contraintes
        if(calco == 'NOEUD') then
        !      vsi = matmul(vsig, vn(:,1))
        !      wpla = dot_product(vnle(nc2,:),vn(:,1))
        else

            call init_vec(vsi0, size(vsig0,1)); call init_vec(vnl0, size(vnle0,1));
            call init_vec(vsi,  size(vb,1))   ; call init_vec(vnl,  size(vb,1));
            call init_vec(vin,  size(vint,1)) ;

            vsi0 = vsig0(:,ipg)
            vnl0 = vnle0(:,ipg)
            vin  = vint(:,ipg)

            !------------------------------------------------------------------------------
            !--- Calcul des contraintes en fonction du modele
            if (inict) vsi = vsi0
            call elem_sig(vsi,vnl,vin,ie,vhep,vb,vnl0,vprel,vdle,ipg)

            vsig(1:size(vsi),ipg) = vsi
            vnle(1:size(vnl),ipg) = vnl
            vint(1:size(vin),ipg) = vin

            wpla = vnl0(nc2) + .5*dot_product(vsi0+vsi,vnl(1:nc1)-vnl0(1:nc1))
            vnle(nc2,ipg) = wpla

            !------------------------------------------------------------------------------
            !--- Gestion de l'element libre
            if ((allocated(elemlibre)).and.(elemlibre(ie)==1)) then
                !print*,'annulation de la contribution de l''element detache',ie
                pdet=0.d0
                vsig(1:size(vsi),ipg) = 0.d0
                vnle(1:size(vnl),ipg) = 0.d0
                vint(1:size(vin),ipg) = 0.d0
                wpla = vnl0(nc2)
                vnle(nc2,ipg) = 0.D0
            endif

            deallocate(vsi0,vnl0)
        endif

        !----------------------------------------------------------------------------------
        !--- Integration sur l'element de l'energie plastique
        wplael = wplael + (pdet*wpla)

        !----------------------------------------------------------------------------------
        !--- Integration des contraintes
        vfint = vfint + pdet*matmul(transpose(vb),vsig(1:size(vsi),ipg))

        !----------------------------------------------------------------------------------

        vke = vke + matmul(transpose(vb),matmul((vhep*pdet),vb))

        !----------------------------------------------------------------------------------
        !--- Nettoyage
        deallocate(vsi,vnl,vin, vn,vb,vhep)

    enddo

    !--------------------------------------------------------------------------------------
    !--- Detection de la rupture d'un element
    call rupture(ie,vsig,vnle,wplael,vprel)

    !--------------------------------------------------------------------------------------
    !--- Stockage dans les vecteurs globaux
    !  Stockage dans vcont des nouvelles contraintes pour PG de l'element ie
    vcont(iloc1 : (iloc1+ idim1 - 1)) = reshape(vsig,(/idim1/))

    !  Stockage dans vnoli des nouvelles defo plast pour PG de l'element ie
    vnoli(iloc2 : (iloc2+ idim2 - 1)) = reshape(vnle,(/idim2/))

    !  Stockage dans vrint des nouvelles variables internes pour PG de l'element ie
    vrint(iloc3 : (iloc3+ idim3 - 1)) = reshape(vint,(/idim3/))

    !--------------------------------------------------------------------------------------
    !--- Calcul final du residu
    vre = vfext - vfint

    !--------------------------------------------------------------------------------------
    !--- desallocation
    !deallocate(ksin)
    deallocate(ksig,vpg,vsig0,vnle0,vsig,vnle,vint)

end subroutine elem_ke



!!=================================================================================!
!   !---------------------------------------------------------------!
!   !      Calcul de la matrice de masse elementaire (explicite)    !
!   !---------------------------------------------------------------!
!   subroutine elem_me(vme,vre,ie,kloce,vprel,vdle)

!       use variables, only : dime, infele, ktypel, nomtype, &
!                              & vcont, vnoli, kcont, knoli, calco, ietatpg
!       use initialisation, only : init_mat, init_vec
!       use lib_elem, only : elem_B, elem_hooke
!       use contraintes
!       implicit none

!       real*8, dimension(:,:), allocatable, intent(inout) :: vme
!       real*8, dimension(:), allocatable, intent(inout) :: vre
!       integer, intent(in) :: ie
!       real*8, dimension(:), intent(in) :: vprel, vdle
!       integer, dimension(:), intent(in) :: kloce

!       integer :: i, ino, ipg
!       integer :: id
!       integer :: nnel, ndle, ndln
!       real*8 :: epais, fvx, fvy, fvz, rho
!       integer, dimension(:,:), allocatable :: ksin
!       real*8, dimension(:,:), allocatable :: ksig
!       real*8, dimension(:), allocatable :: vpg
!       real*8, dimension(:), allocatable :: vfint, vfext
!       real*8, dimension(:,:), allocatable :: vsig0, vnle0, vsig, vnle
!       real*8, dimension(:), allocatable :: vsi0, vnl0, vsi, vnl
!       real*8, dimension(:,:), allocatable :: vn, vb, vh
!       integer :: nc1, nc2, npg, idim1, idim2, iloc1, iloc2, idm1, idm2
!       real*8 :: detj, wpla, wplael, poids, pdet
!       real*8, dimension(:,:), allocatable :: N


!       ! Recuperation de l'epaisseur (dime=2) et des forces de volume (dime=2 et 3)
!       id = size(vprel)

!       if(dime == 2) then
!          if (vprel(2)==3) epais = vprel(id-2) ! contraintes planes (CP)
!          fvx = vprel(id-1)
!          fvy = vprel(id)
!       else if(dime == 3) then
!          fvx = vprel(id-2)
!          fvy = vprel(id-1)
!          fvz = vprel(id)
!       else
!          print*, 'Elem_me : Cas non implante'
!          stop
!       endif

!       !------- Recuperation de la masse volumique -----
!       rho = vprel(3)
!       if(rho == 0) then
!          print'(a7,1x,i5)', 'Element', ie, ' : masse volumique nulle'
!          stop
!       endif

!       !------- Recuperation des informations sur les elements ------
!       call init_mat(ksin, size(infele(ktypel(ie))%ksin,1), size(infele(ktypel(ie))%ksin,2))
!       ksin = infele(ktypel(ie))%ksin
!       nnel = infele(ktypel(ie))%nnel
!       ndln = infele(ktypel(ie))%ndln !?
!       nc1  = infele(ktypel(ie))%ncgr     ! nombre de composantes du gradient
!       nc2  = nc1 + 1                     ! nombre de composantes non lineaires

!       !------- Recuperation des points d'integration ----------
!       call init_vec(vpg, size(infele(ktypel(ie))%W))
!       call init_mat(ksig, size(infele(ktypel(ie))%Q,1), size(infele(ktypel(ie))%Q,2))

!       vpg = infele(ktypel(ie))%W
!       ksig = infele(ktypel(ie))%Q
!       npg = size(ksig,1)

!       !------- initialisations vecteurs globaux ---------------
!       ndle=size(kloce)
!       ndln=ndle/nnel !?
!       call init_mat(vme,ndle,ndle); call init_vec(vfint,ndle); call init_vec(vfext,ndle)

!       !----- localisation des donnees elementaires dans les vecteurs globaux -----
!       if (calco == 'NOEUD') then
!           idim1=nnel*nc1;
!           idim2=nnel*nc2;
!       elseif (calco == 'GAUSS') then
!           idim1=npg*nc1;
!           idim2=npg*nc2;
!       endif
!       iloc1=kcont(ie)
!       iloc2=knoli(ie)
!       idm1=idim1/nc1
!       idm2=idim2/nc2

!       !----- Recuperation des vecteurs elementaires dans vcont et vnoli ------
!       call init_mat(vsig0, nc1, idm1); call init_mat(vnle0, nc2, idm2)

!       vsig0  = reshape(vcont(iloc1 : (iloc1+ idim1 - 1)),(/ nc1, idm1/))
!       vnle0 = reshape(vnoli(iloc2:(iloc2+idim2-1)), (/nc2, idm2/))

!       !------------ Si calcul des contraintes aux noeuds -----------
!       if (calco == 'NOEUD') then

!            call init_mat(vsig, nc1, nnel); call init_mat(vnle, nc2, nnel)

!            do ino = 1, nnel
!                   !call init_vec(vsi0, size(vsig0(:,ino)))
!                  !call init_vec(vnl0, size(vnle0(:,ino)))
!                  !------- Calcul des fonctions d'interpolation et des derivees --
!                  !call elem_B(vn, vb, detj, DBLE(ksin(ino,:)), ie)
!                  !vsi0 = vsig0(:,ino)
!                  !vnl0 = vnle0(:,ino)

!                  !------- Calcul des contraintes en fonction du modele -----
!                  !call elem_sig(vsi,vnl,ie,vh,vb,vnl0)
!                  !vsig(:, ino) = vsi
!                  !vnle(1 : nc1, ino) = vnl(1:nc1)
!                  !wpla = vnl0(nc2) + .5*dot_product(vsi0+vsi,vnl(1:nc1)-vnl0(1:nc1))
!                  !vnle(nc2,ino) = wpla
!                  !deallocate(vsi0); deallocate(vnl0); !deallocate(vsi)
!                  !deallocate(vnl)
!            enddo

!       else
!            call init_mat(vsig, nc1, npg); call init_mat(vnle, nc2, npg)
!       end      if

!       !----------- Initialisation pour calcul de l'energie plastique -------
!       wplael = 0.0d0

!       !--- Si calcul des contraintes aux points de Gauss pour integration et
!       !      calcul du residu elementaire et de la matrice de masse -------

!       do ipg = 1, npg
!           poids = vpg(ipg)

!           !-----  Calcul des fonctions d'interpolation et des derivees ------
!           call elem_B(vn,vb,detj,ksig(ipg,:),ie)
!           pdet = detj*poids*epais

!           call init_mat(N, ndln,ndle)
!           do i = 1, dime
!               N(i, i:ndle:ndln) = vn(:,1)
!           enddo

!           !---------------- Integration matrice vme ------------------------
!           vme = vme + (rho*pdet)*matmul(transpose(N),N)

!           !-------- Partie de vre due au chargement volumique --------------
!           vfext(1:ndln*nnel:dime) = vfext(1:ndln*nnel:dime) + (fvx*pdet)*vn(:,1)
!           vfext(2:ndln*nnel:dime) = vfext(2:ndln*nnel:dime) + (fvy*pdet)*vn(:,1)

!           if (dime==3) then
!               vfext(3:ndle:dime) = vfext(3:ndle:dime) + (fvz*pdet)*vn(1,:)
!           endif

!           !---- Recuperation (aux noeuds) ou calcul (aux PG) des contraintes ---
!           if(calco == 'NOEUD') then
!               vsi = matmul(vsig, vn(:,1))
!               wpla = dot_product(vnle(nc2,:),vn(:,1))

!           else

!               call init_vec(vsi0, size(vsig0(:,ino)))
!               call init_vec(vnl0, size(vnle0(:,ino)))

!               vsi0 = vsig0(:,ipg)
!               vnl0 = vnle0(:,ipg)
!! todo ......

!               deallocate(vsi0); deallocate(vnl0)

!           endif

!           deallocate(N)
!      enddo



!      !---------------------------- desallocation --------------------------
!      deallocate(ksin,ksig,vpg,vfint,vfext,vsig0,vnle0,vsig,vnle,vn,vb)


!    end subroutine elem_me

!------------------------------------------------------------------------------------------------------

end module calc_elem