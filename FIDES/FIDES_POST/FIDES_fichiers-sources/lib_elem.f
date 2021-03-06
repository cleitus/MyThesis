module lib_elem

!**********************************************************!
!       Divers outils utilises au niveau de l'element      !
!**********************************************************!

contains

!=================================================================================!

!---------------------------------------------------------------------------------!
!                Fonction donnant acces aux matrices de hooke                     !
!                              relatives aux elements                             !
!  Entrees :                                                                      !
!  - typel : le type de l'element                                                 !
!  - vprel : proprietes elementaires                                              !
!                                                                                 !
!  Sortie :                                                                       !
!  - vh : matrice de hooke                                                        !
!---------------------------------------------------------------------------------!
   subroutine elem_hooke(vh,typel,vprel)

    use variables, only : dime

     implicit none

     real*8, dimension(:,:), allocatable, intent(out) :: vh
     character(len = 5), intent(in) :: typel
     real*8, dimension(:), intent(in) :: vprel
     real*8 :: eh, gh, eh1, eh2, cnu, c1
     !--- Caracteristiques poutre : section (A), inerties (I,J), diametre (Db)
     real*8 :: ah, A, I, J, Db
     real*8, parameter :: pi=dacos(-1.d0)
     !--- Orthotropie
     real*8 :: E1, E2, E3, G12, G23, G31, nu12, nu21, nu23, nu32, nu31, nu13, delta
     integer :: iloi
     
     !--- Verification orthotropie en fontion de la loi
     iloi = int(vprel(1))

     ! Tenseur du module d'elasticite des elements d'interface
     if ((typel=='EJQ4').or.(typel=='EJQ6').or.(typel=='EJT6')) then
        select case (dime)
          case (2)
            allocate(vh(dime,dime))
            vh(1,:)=1.d11*(/1. , 0./)
            vh(2,:)=1.d11*(/0. , 1./)

          case (3)
            allocate(vh(dime,dime))
            vh(1,:) = 1.d11*(/1.,0.,0./)
            vh(2,:) = 1.d11*(/0.,1.,0./)
            vh(3,:) = 1.d11*(/0.,0.,1./)

          case default
            stop 'FIDES_hooke : element d''inteface non encore implante'
        end select

     ! Tenseur du module d'elasticite des elements barres
     elseif (typel == 'BAR2') then
         eh = vprel(4)
         allocate(vh(1,1))
         vh = eh

     ! Tenseur du module d'elasticite des elements poutres
     elseif ((typel == 'BEA2') .or. (typel == 'BEF2')) then
         eh=vprel(4);               ! terme EI
         if (typel == 'BEF2') then
             ah = vprel(5);         ! terme EA
             allocate(vh(2,2))
             vh(1,:) = (/ ah   , 0.d0 /)
             vh(2,:) = (/ 0.d0 , eh   /)
         else
             allocate(vh(1,1))
             vh = eh
         end if

     elseif (typel == 'BEF3') then
         Db  = vprel(2)    ! diametre de la barre
         eh  = vprel(3)    ! module d'Young
         cnu = vprel(4)    ! coefficient de Poisson

         gh  = eh/2.d0/(1+cnu) ! module de cisaillement
         A   = pi/4.d0*(Db**2)
         I   = pi/64.d0*(Db**4)
         J   = pi/32.d0*(Db**4)

         ah  = eh*A    ! terme EA
         eh1 = eh*I    ! terme EI
         eh2 = gh*J    ! terme GJ

         allocate(vh(4,4))
         vh(1,:) = (/ ah   , 0.d0 , 0.d0 , 0.d0/)
         vh(2,:) = (/ 0.d0 , eh1  , 0.d0 , 0.d0/)
         vh(3,:) = (/ 0.d0 , 0.d0 , eh1  , 0.D0/)
         vh(4,:) = (/ 0.d0 , 0.d0 , 0.D0 , eh2 /)

     ! Tenseur du module d'elasticite des elements massifs
     else
         if (iloi==2 .or. iloi/10==2 .or. iloi/100==2) then                    ! (iloi==2) => orthotropie
             select case (dime)
                 case (1)
                     stop 'Subroutine elem_hooke : erreur orthotropie non define en 1D'
                 case (2)
                     E1=vprel(4)                   ! module
                     E2=vprel(5)                   ! module
                     G12=vprel(6)                  ! module
                     nu12=vprel(7)                 ! coefficient de Poisson
                     !-- on force : nu21*E1 = nu12*E2 (directement dans la matrice)
                     
                     if(vprel(2)==3) then          ! contraintes planes
                         allocate(vh(3,3))
                         nu21 = nu12*E2/E1
                         delta   = 1.d0/(1-nu12*nu21)
                         vh(1,:) = delta*(/     E1, nu12*E2, 0d0/)
                         vh(2,:) = delta*(/nu21*E1,      E2, 0d0/)
                         vh(3,:) =       (/    0d0,     0d0, G12/)
                     elseif(vprel(2)==1) then      ! deformations planes
                         stop 'Subroutine elem_hooke : erreur orthotropie non define en deformations planes'
                         !allocate(vh(3,3))
                         !nu21 = nu12*E2/E1
                         !nu31 = nu13*E3/E1
                         !nu32 = nu23*E3/E2
                         !delta   = E1*E2*E3/(1-nu12*nu21-nu23*nu32-nu31*nu13-2*nu12*nu23*nu31)
                         
                         !vh(1,:) = delta*(/   (1-nu23*nu32)/(E2*E3), (nu21-nu31*nu23)/(E2*E3), 0d0/)
                         !vh(2,:) = delta*(/(nu12-nu13*nu32)/(E1*E3),    (1-nu31*nu13)/(E1*E3), 0d0/)
                         !vh(3,:) =       (/                     0d0,                      0d0, G12/)
                         
                     end if

                 case (3)
                     E1=vprel(3)                   ! module
                     E2=vprel(4)                   ! module
                     E3=vprel(5)                   ! module
                     G12=vprel(6)                  ! module
                     G23=vprel(7)                  ! module
                     G31=vprel(8)                  ! module
                     nu12=vprel(9)                 ! coefficient de Poisson
                     nu23=vprel(10)                 ! coefficient de Poisson
                     nu31=vprel(11)                ! coefficient de Poisson
                     
                     nu21 = nu12*E2/E1
                     nu31 = nu13*E3/E1
                     nu32 = nu23*E3/E2
                     delta   = E1*E2*E3/(1-nu12*nu21-nu23*nu32-nu31*nu13-2*nu12*nu23*nu31)
                     
                     vh(1,:) = delta*(/   (1-nu23*nu32)/(E2*E3), (nu21-nu31*nu23)/(E2*E3), (nu31-nu21*nu32)/(E2*E3), 0d0, 0d0, 0d0/)
                     vh(2,:) = delta*(/(nu12-nu13*nu32)/(E1*E3),    (1-nu31*nu13)/(E1*E3), (nu32-nu31*nu12)/(E1*E3), 0d0, 0d0, 0d0/)
                     vh(3,:) = delta*(/(nu13-nu12*nu23)/(E2*E1), (nu32-nu13*nu21)/(E2*E1),    (1-nu12*nu21)/(E2*E1), 0d0, 0d0, 0d0/)
                     vh(4,:) =       (/                     0d0,                      0d0,                      0d0, G12, 0d0, 0d0/)
                     vh(5,:) =       (/                     0d0,                      0d0,                      0d0, 0d0, G23, 0d0/)
                     vh(6,:) =       (/                     0d0,                      0d0,                      0d0, 0d0, 0d0, G31/)

                 case default
                     stop 'FIDES_hooke : element non encore implante'

             end select
         elseif(iloi==1 .or. iloi/10==1 .or. iloi/100==1) then                 ! (iloi==1) => isotropie
             select case (dime)
                 case (1)
                     eh=vprel(4)
                     vh=eh

                 case (2)
                     eh=vprel(4)                   ! module d'Young
                     cnu=vprel(5)                  ! coefficient de Poisson
                     if(vprel(2)==3) then          ! contraintes planes
                         allocate(vh(3,3))
                         vh(1,:) = eh/(1-cnu*cnu)*(/1d0, cnu, 0d0/)
                         vh(2,:) = eh/(1-cnu*cnu)*(/cnu, 1d0, 0d0/)
                         vh(3,:) = eh/(1-cnu*cnu)*(/0d0, 0d0, (1-cnu)/2./)
                     elseif(vprel(2)==1) then      ! deformations planes
                         allocate(vh(3,3))
                         c1 = eh/((1+cnu)*(1-2*cnu))
                         vh(1,:)=(/c1*(1-cnu),   c1*cnu,         0d0          /)
                         vh(2,:)=(/c1*cnu,       c1*(1-cnu),     0d0          /)
                         vh(3,:)=(/0d0,          0d0,            .5*eh/(1+cnu)/)
                     end if

                 case (3)
                     eh=vprel(3)
                     cnu=vprel(4)
                     c1=eh/((1+cnu)*(1-2*cnu))
                     allocate(vh(6,6))
                     vh(1,:) = c1*(/(1-cnu),   cnu,    cnu,       0d0,         0d0,       0d0/)
                     vh(2,:) = c1*(/cnu,    (1-cnu),   cnu,       0d0,         0d0,       0d0/)
                     vh(3,:) = c1*(/cnu,       cnu,   (1-cnu),    0d0,         0d0,       0d0/)
                     vh(4,:) = c1*(/ 0d0,       0d0,     0d0,   (1-2*cnu)/2.,   0d0,       0d0/)
                     vh(5,:) = c1*(/ 0d0,        0d0,     0d0,     0d0,    (1-2*cnu)/2.,    0d0/)
                     vh(6,:) = c1*(/ 0d0,        0d0,     0d0,      0d0,        0d0, (1-2*cnu)/2./)

                 case default
                     stop 'FIDES_hooke : element non encore implante'

             end select
         end if
     end if

   end subroutine elem_hooke

!========================================================================
!-----------------------------------------------------------------------!
!          Fonction de positionnement des ddls locaux dans les          !
!                      vecteurs globaux                                 !
!  Entree :                                                             !
!  - ie : numero de l'element                                           !
!                                                                       !
!  Sortie :                                                             !
!  - kloce : positionnement des ddls locaux dans les vecteurs globaux   !
!-----------------------------------------------------------------------!
   subroutine elem_kloce(kloce, ie, ndle)

       use variables, only : infele, kconec, ktypel, infnoe

       implicit none

       integer, intent(in) :: ie
       integer, intent(out) :: ndle
       integer, dimension(100), intent(inout) :: kloce
       integer :: nnel, ndln, k

       nnel = infele(ktypel(ie))%nnel
       ndln = infele(ktypel(ie))%ndln
       ndle = nnel*ndln

       do k = 1, nnel
          kloce((k-1)*ndln+1:k*ndln) = infnoe(kconec(ie,k))%dln(1:ndln)
       end do

    end subroutine elem_kloce


! Version de elem_kloce differente adaptee à une variable globale unique


 subroutine elem_kloce2(ie,ndle)

       use variables, only : infele, kconec, ktypel, infnoe, kloce
       use initialisation, only : init_mat, init_vec

       implicit none

       integer, intent(in) :: ie
       integer,intent(inout)::ndle
       integer :: nnel, ndln, k

       nnel = infele(ktypel(ie))%nnel
       ndln = infele(ktypel(ie))%ndln
       ndle=nnel*ndln

       do k = 1, nnel
          kloce((k-1)*ndln+1:k*ndln) = infnoe(kconec(ie,k))%dln(1:ndln)
       end do

    end subroutine elem_kloce2

!============================================================================
!---------------------------------------------------------------------------!
!           Fonction donnant acces aux informations relatives               !
!                               aux elements                                !
!  Entree :                                                                 !
!  - typelem : le type de l'element                                         !
!                                                                           !
!  Sortie :                                                                 !
!  - elem : informations relatives aux elements                             !
!---------------------------------------------------------------------------!

   subroutine elem_info(elem, typelem)

      use variables, only : forme
      use initialisation, only : init_mat, init_vec

      implicit none

      character(len = *), intent(in) :: typelem
      type (forme), intent(out) :: elem
      real*8, dimension(:,:), allocatable :: Q0
      real*8, dimension(:), allocatable :: W0

      select case (typelem)
         case ('EJQ4')

            elem%nnel = 4
            elem%ndln = 2
            elem%order = 2
            !--- Gauss (2 points)
            !call util_quad(Q0, W0, elem%order, 'GAUSS', 1)
            call init_vec(elem%W,3)
            call init_mat(elem%Q,3,1)
            !elem%W(2:3) = W0
            !elem%Q(2:3,:) = Q0
            !--- Newton Cotes (2 points)
            elem%W = (/ 0.d0, 1.d0, 1.d0 /)
            elem%Q(1,1) = 0.d0
            elem%Q(2,1) = 1.d0
            elem%Q(3,1) = -1.d0
            !--- Newton Cotes (3 points)
            !elem%W = (/ 1.333333333d0, .333333333d0, .333333333d0 /)
            !elem%Q(1,1) = 0.d0
            !elem%Q(2,1) = 1.d0
            !elem%Q(3,1) = -1.d0

            call init_mat(elem%ksin,4,2)
            call init_mat(elem%face,2,2)
            elem%ksin(1,:) = (/-1.d0 , 0.d0/)
            elem%ksin(2,:) = (/ 1.d0 , 0.d0/)
            elem%ksin(3,:) = (/1.d0 ,0.d0/)
            elem%ksin(4,:) = (/-1.d0,0.d0/)

            elem%ncgr = 2
            elem%face(1,:) = (/1, 2/)
            elem%face(2,:) = (/3, 4/)

            !deallocate(W0,Q0)

         case ('EJQ6')

            elem%nnel = 6
            elem%ndln = 2
            elem%order = 3
            !call util_quad(Q0, W0, elem%order, 'GAUSS', 1)
            call init_vec(elem%W,3)
            call init_mat(elem%Q,3,1)
            !elem%W = (/ W0(3), W0(1), W0(2) /)
            !elem%Q(1,1) = Q0(3,1)
            !elem%Q(2,1) = Q0(1,1)
            !elem%Q(3,1) = Q0(2,1)
            ! Integration Newton-Cotes à trois points
            elem%W = (/ 1.333333333d0, .333333333d0, .333333333d0 /)
            elem%Q(1,1) = 0.d0
            elem%Q(2,1) = 1.d0
            elem%Q(3,1) = -1.d0

            call init_mat(elem%ksin,6,2)
            call init_mat(elem%face,2,3)
            elem%ksin(1,:) = (/-1.d0,0.d0/)
            elem%ksin(2,:) = (/ 1.d0,0.d0/)
            elem%ksin(3,:) = (/ 1.d0,0.d0/)
            elem%ksin(4,:) = (/-1.d0,0.d0/)
            elem%ksin(5,:) = (/ 0.d0,0.d0/)
            elem%ksin(6,:) = (/ 0.d0,0.d0/)
            elem%ncgr = 2
            elem%face(1,:) = (/1, 5, 2/)
            elem%face(2,:) = (/3, 6, 4/)

            !deallocate(W0,Q0)

         case ('EJT6')

            !---- Nombre de noeuds
            elem%nnel = 6
            !---- Nombre de ddl par noeud
            elem%ndln = 3
            !---- Ordre d'integration element normal
            elem%order = 2

            !---- Points de Gauss
            call util_quad(Q0, W0, elem%order, 'TRIANGULAR', 2)

            call init_vec(elem%W,4)
            call init_mat(elem%Q,4,2)
            elem%W(1) = 0.d0
            elem%W(2:4) = W0

            elem%Q(1,:) = (/ 0.33333333333333d0, 0.33333333333333d0 /)
            elem%Q(2:4,:) = Q0

            deallocate(W0,Q0)

            !---- Coordonnees reduites des noeuds
            call init_mat(elem%ksin,6,3)
            elem%ksin(1,:) = (/0. , 0. , 0./)
            elem%ksin(2,:) = (/1. , 0. , 0./)
            elem%ksin(3,:) = (/0. , 1. , 0./)
            elem%ksin(4,:) = (/0. , 0. , 0./)
            elem%ksin(5,:) = (/1. , 0. , 0./)
            elem%ksin(6,:) = (/0. , 1. , 0./)
            !---- Nombre de composantes du gradient
            elem%ncgr = 3
            !---- Numerotation des points par face (pour traces graphiques)
            call init_mat(elem%face,2,3)
            elem%face(1,:) = (/1, 2, 3/)
            elem%face(2,:) = (/4, 5, 6/)

         case ('BAR2') ! element barre
            !---- Nombre de noeuds
            elem%nnel = 2
            !---- Nombre de ddl par noeud
            elem%ndln = 1 !2
            !---- Ordre d'integration element normal
            elem%order = 2
            !---- Points de Gauss
            call util_quad(elem%Q, elem%W, elem%order, 'GAUSS', 1)
            !---- Nombre de composantes du gradient
            elem%ncgr = 1
            !---- Coordonnees reduites des noeuds
            call init_mat(elem%ksin,1,2)
            elem%ksin(1,:) = (/-1.d0, 1.d0/)
            !---- Numerotation des points par face (pour traces graphiques)
            call init_mat(elem%face,1,2)
            elem%face(1,:) = (/1, 2/)

         case ('BEA2') ! element poutre (v,theta)
             !---- Nombre de noeuds
             elem%nnel = 2
             !---- Nombre de ddl par noeud
             elem%ndln = 3
             !---- Ordre d'integration element normal
             elem%order = 2
             !---- Points de Gauss
             call util_quad(elem%Q, elem%W, elem%order, 'GAUSS', 1)
             !---- Coordonnees reduites des noeuds
             call init_mat(elem%ksin,1,2);
             elem%ksin(1,:)=(/ -1.d0 , 1.d0 /)
             !---- Nombre de composantes du gradient
             elem%ncgr = 1
             !---- Numerotation des points par face (pour traces graphiques)
             call init_mat(elem%face,1,2)
             elem%face(1,:)=(/ 1 , 2 /)

         case ('BEF2') ! element poutre "frame" (u,v,theta)
             !---- Nombre de noeuds
             elem%nnel = 2
             !---- Nombre de ddl par noeud
             elem%ndln = 3
             !---- Ordre d'integration element normal
             elem%order = 2
             !---- Points de Gauss
             call util_quad(elem%Q, elem%W, elem%order, 'GAUSS', 1)
             !---- Coordonnees reduites des noeuds
             call init_mat(elem%ksin,2,2);
             elem%ksin(1,:)=(/ -1.d0 , 1.d0 /)
             elem%ksin(2,:)=(/  0.d0 , 0.d0 /)
             !---- Nombre de composantes du gradient
             elem%ncgr = 2
             !---- Numerotation des points par face (pour traces graphiques)
             call init_mat(elem%face,1,2)
             elem%face(1,:)=(/ 1 , 2 /)

         case ('BEF3') ! element poutre 3D (u,v,w,theta1,theta2,theta3)
             !---- Nombre de noeuds
             elem%nnel = 2
             !---- Nombre de ddl par noeud
             elem%ndln = 6
             !---- Ordre d'integration element normal
             elem%order = 2
             !---- Points de Gauss
             call util_quad(elem%Q, elem%W, elem%order, 'GAUSS', 1)
             !---- Coordonnees reduites des noeuds
             call init_mat(elem%ksin,3,2);
             elem%ksin(1,:)=(/ -1.d0 , 1.d0 /)
             elem%ksin(2,:)=(/  0.d0 , 0.d0 /)
             elem%ksin(3,:)=(/  0.d0 , 0.d0 /)
             !---- Nombre de composantes du gradient
             elem%ncgr = 4
             !---- Numerotation des points par face (pour traces graphiques)
             call init_mat(elem%face,1,2)
             elem%face(1,:)=(/ 1 , 2 /)

         case ('MBT3')
            elem%nnel = 3
            elem%ndln = 2
            elem%order = 1
            call util_quad(elem%Q, elem%W, elem%order, 'TRIANGULAR', 2)
            call init_mat(elem%ksin,3,2); call init_mat(elem%face,3,2)
            elem%ksin(1,:) = (/0.d0,0.d0/)
            elem%ksin(2,:) = (/1.d0,0.d0/)
            elem%ksin(3,:) = (/0.d0,1.d0/)
            elem%ncgr = 3
            elem%face(1,:) = (/1, 2/)
            elem%face(2,:) = (/2, 3/)
            elem%face(3,:) = (/3, 1/)

         case ('MBT6')
            elem%nnel = 6
            elem%ndln = 2
            elem%order = 2
            call util_quad(elem%Q, elem%W, elem%order, 'TRIANGULAR', 2)
            call init_mat(elem%ksin,6,2); call init_mat(elem%face,3,3)
            elem%ksin(1,:) = (/0.d0,0.d0/)
            elem%ksin(2,:) = (/1.d0,0.d0/)
            elem%ksin(3,:) = (/0.d0,1.d0/)
            elem%ksin(4,:) = (/.5d0,0.d0/)
            elem%ksin(5,:) = (/.5d0,.5d0/)
            elem%ksin(6,:) = (/0.d0,.5d0/)
            elem%ncgr = 3
            elem%face(1,:) = (/1, 4, 2/)
            elem%face(2,:) = (/2, 5, 3/)
            elem%face(3,:) = (/3, 6, 1/)

         case ('MBQ4')
            elem%nnel = 4
            elem%ndln = 2
            elem%order = 2
            call util_quad(elem%Q, elem%W, elem%order, 'GAUSS', 2)
            call init_mat(elem%ksin,4,2); call init_mat(elem%face,4,2)
            elem%ksin(1,:) = (/-1.d0,-1.d0/)
            elem%ksin(2,:) = (/ 1.d0,-1.d0/)
            elem%ksin(3,:) = (/ 1.d0, 1.d0/)
            elem%ksin(4,:) = (/-1.d0, 1.d0/)
            elem%ncgr = 3
            elem%face(1,:) = (/1, 2/)
            elem%face(2,:) = (/2, 3/)
            elem%face(3,:) = (/3, 4/)
            elem%face(4,:) = (/4, 1/)

         case ('MBQ8')
            elem%nnel = 8
            elem%ndln = 2
            elem%order = 3
            call util_quad(elem%Q, elem%W, elem%order, 'GAUSS', 2)
            call init_mat(elem%ksin,8,2); call init_mat(elem%face,4,3)
            elem%ksin(1,:) = (/-1.d0,-1.d0/)
            elem%ksin(2,:) = (/ 1.d0,-1.d0/)
            elem%ksin(3,:) = (/ 1.d0, 1.d0/)
            elem%ksin(4,:) = (/-1.d0, 1.d0/)
            elem%ksin(5,:) = (/ 0.d0,-1.d0/)
            elem%ksin(6,:) = (/ 1.d0, 0.d0/)
            elem%ksin(7,:) = (/ 0.d0, 1.d0/)
            elem%ksin(8,:) = (/-1.d0, 0.d0/)
            elem%ncgr = 3
            elem%face(1,:) = (/1, 5, 2/)
            elem%face(2,:) = (/2, 6, 3/)
            elem%face(3,:) = (/3, 7, 4/)
            elem%face(4,:) = (/4, 8, 1/)

         case ('MTT4')
            elem%nnel = 4
            elem%ndln = 3
            elem%order = 1
            call util_quad(elem%Q, elem%W, elem%order, 'TRIANGULAR', 3)
            call init_mat(elem%ksin,4,3); call init_mat(elem%face,4,3)
            elem%ksin(1,:) = (/0.d0,0.d0,0.d0/)
            elem%ksin(2,:) = (/1.d0,0.d0,0.d0/)
            elem%ksin(3,:) = (/0.d0,1.d0,0.d0/)
            elem%ksin(4,:) = (/0.d0,0.d0,1.d0/)
            elem%ncgr = 6
            elem%face(1,:) = (/1, 2, 3/)
            elem%face(2,:) = (/1, 2, 4/)
            elem%face(3,:) = (/1, 4, 3/)
            elem%face(4,:) = (/4, 2, 3/)

         case ('MTP6')
            elem%nnel = 6
            elem%ndln = 3
            elem%order = 2
            call util_quad(elem%Q, elem%W, elem%order, 'PENTAHEDRAL', 3)

            call init_mat(elem%ksin,6,3); call init_mat(elem%face,5,4)
            elem%ksin(1,:) = (/0.d0,0.d0,-1.d0/)
            elem%ksin(2,:) = (/1.d0,0.d0,-1.d0/)
            elem%ksin(3,:) = (/0.d0,1.d0,-1.d0/)
            elem%ksin(4,:) = (/0.d0,0.d0, 1.d0/)
            elem%ksin(5,:) = (/1.d0,0.d0, 1.d0/)
            elem%ksin(6,:) = (/0.d0,1.d0, 1.d0/)

            elem%ncgr = 6
            elem%face(1,:) = (/1, 2, 3, 0/)
            elem%face(2,:) = (/4, 6, 5, 0/)
            elem%face(3,:) = (/1, 4, 5, 2/)
            elem%face(4,:) = (/2, 5, 6, 3/)
            elem%face(5,:) = (/3, 6, 4, 1/)

         case default
            stop 'FIDES_infele : element non encore implante'
       end select

    end subroutine elem_info


!************************  Interpolation et quadrature **********************

!============================================================================
!-----------------------------------------------------------!
!      Bibliothèque de poids et points d'intégration        !
!-----------------------------------------------------------!

   subroutine util_quad (Q, W, quadorder, qt, sdim) ! modif ici w en ligne

  ! The function quadrature returns a n vector W of quadrature
  ! weights and a n x dim matrix of quadrature points, where n is the
  ! number of quadrature points. The function is called as follows:

  ! [W,Q]=quadrature( nint, type, dim )

  ! nint is the quadrature order, type is the type of quadrature
  ! (i.e. gaussian, triangular, etc.. ) and dim is the number of spacial
  ! dimentions of the problem.  The default for type is GAUSS and the default for dim is unity.

  ! wrQ=quadrature(nint,'TRIANGULAR',2);written by Jack Chessa
  !           j-chessa@northwestern.edu
  ! Department of Mechanical Engineering
  ! Northwestern University

      use initialisation, only : init_mat, init_vec

      implicit none

      real*8, dimension(:,:), allocatable, intent(inout) :: Q
      real*8, dimension(:), allocatable, intent(inout) :: W
      integer, intent(in) :: quadorder
      character(len=*), intent(in) :: qt
      integer, intent(in) :: sdim
      integer :: quadorder1
      real*8, dimension(:), allocatable :: r1pt, r1wt
      integer :: n, i, j, k

      ! Voir pour argument par default

      quadorder1 = quadorder ! Pour pouvoir modifier quadorder

      if(qt == 'GAUSS') then

          if ( quadorder > 8 )  then ! check for valid quadrature order
               print*, 'Order of quadrature too high for Gaussian Quadrature'
               quadorder1 = 8;
          end if

          call init_mat(Q,quadorder1**sdim, sdim); call init_vec(W,quadorder1**sdim)
          call init_vec(r1pt,quadorder1); call init_vec(r1wt,quadorder1)

          select case (quadorder1)

              case (1)
                 r1pt(1) = 0.000000000000000d0
                 r1wt(1) = 2.000000000000000d0

              case (2)
                 r1pt(1) = 0.577350269189626d0
                 r1pt(2) =-0.577350269189626d0

                 r1wt(1) = 1.000000000000000d0
                 r1wt(2) = 1.000000000000000d0

             case (3)
                 r1pt(1) = 0.774596669241483d0
                 r1pt(2) =-0.774596669241483d0
                 r1pt(3) = 0.000000000000000d0

                 r1wt(1) = 0.555555555555556d0
                 r1wt(2) = 0.555555555555556d0
                 r1wt(3) = 0.888888888888889d0

             case (4)
                 r1pt(1) = 0.861134311594053d0
                 r1pt(2) =-0.861134311594053d0
                 r1pt(3) = 0.339981043584856d0
                 r1pt(4) =-0.339981043584856d0

                 r1wt(1) = 0.347854845137454d0
                 r1wt(2) = 0.347854845137454d0
                 r1wt(3) = 0.652145154862546d0
                 r1wt(4) = 0.652145154862546d0

              case (5)
                 r1pt(1) = 0.906179845938664d0
                 r1pt(2) =-0.906179845938664d0
                 r1pt(3) = 0.538469310105683d0
                 r1pt(4) =-0.538469310105683d0
                 r1pt(5) = 0.000000000000000d0

                 r1wt(1) = 0.236926885056189d0
                 r1wt(2) = 0.236926885056189d0
                 r1wt(3) = 0.478628670499366d0
                 r1wt(4) = 0.478628670499366d0
                 r1wt(5) = 0.568888888888889d0

              case (6)
                 r1pt(1) = 0.932469514203152d0
                 r1pt(2) =-0.932469514203152d0
                 r1pt(3) = 0.661209386466265d0
                 r1pt(4) =-0.661209386466265d0
                 r1pt(5) = 0.238619186003152d0
                 r1pt(6) =-0.238619186003152d0

                 r1wt(1) = 0.171324492379170d0
                 r1wt(2) = 0.171324492379170d0
                 r1wt(3) = 0.360761573048139d0
                 r1wt(4) = 0.360761573048139d0
                 r1wt(5) = 0.467913934572691d0
                 r1wt(6) = 0.467913934572691d0

              case (7)
                 r1pt(1) =  0.949107912342759d0
                 r1pt(2) = -0.949107912342759d0
                 r1pt(3) =  0.741531185599394d0
                 r1pt(4) = -0.741531185599394d0
                 r1pt(5) =  0.405845151377397d0
                 r1pt(6) = -0.405845151377397d0
                 r1pt(7) =  0.000000000000000d0

                 r1wt(1) = 0.129484966168870d0
                 r1wt(2) = 0.129484966168870d0
                 r1wt(3) = 0.279705391489277d0
                 r1wt(4) = 0.279705391489277d0
                 r1wt(5) = 0.381830050505119d0
                 r1wt(6) = 0.381830050505119d0
                 r1wt(7) = 0.417959183673469d0

              case (8)
                 r1pt(1) =  0.960289856497536d0
                 r1pt(2) = -0.960289856497536d0
                 r1pt(3) =  0.796666477413627d0
                 r1pt(4) = -0.796666477413627d0
                 r1pt(5) =  0.525532409916329d0
                 r1pt(6) = -0.525532409916329d0
                 r1pt(7) =  0.183434642495650d0
                 r1pt(8) = -0.183434642495650d0

                 r1wt(1) = 0.101228536290376d0
                 r1wt(2) = 0.101228536290376d0
                 r1wt(3) = 0.222381034453374d0
                 r1wt(4) = 0.222381034453374d0
                 r1wt(5) = 0.313706645877887d0
                 r1wt(6) = 0.313706645877887d0
                 r1wt(7) = 0.362683783378362d0
                 r1wt(8) = 0.362683783378362d0

              case default
                stop 'Order of quadrature to high for Gaussian Quadrature';

          end select ! end of quadorder switch

          n = 1

          if(sdim == 1) then
             do i = 1, quadorder1
                   Q(n,:) =  r1pt(i)
                 W(n) = r1wt(i)
                 n = n + 1
             end do

          else if (sdim == 2) then
             do i = 1, quadorder1
                do j = 1, quadorder1
                   Q(n,:) = (/r1pt(i), r1pt(j)/)
                   W(n) = r1wt(i)*r1wt(j)
                   n = n+1;
                end do
             end do

          else ! sdim == 3
             do i = 1, quadorder1
                 do j = 1, quadorder1
                     do k = 1, quadorder1
                         Q(n,:) = (/r1pt(i), r1pt(j), r1pt(k)/)
                         W(n) = r1wt(i)*r1wt(j)*r1wt(k);
                         n = n+1;
                     end do
                 end do
             end do

          end if

        deallocate(r1pt); deallocate(r1wt)

     ! END OF GAUSSIAN QUADRATURE DEFINITION

      else if (qt == 'TRIANGULAR') then
          if ( sdim == 3 ) then !-- TETRAHEDRE

             if ( quadorder /= 1 .and.  quadorder /= 2 .and. quadorder /= 3  ) then
                ! check for valid quadrature order
                print*, 'Incorect quadrature order for triangular quadrature'
                quadorder1 = 1;
             end if

             if  ( quadorder1 == 1 ) then
                call init_mat(Q,1,3); call init_vec(W,1)
                Q(1,:) = (/ 0.25, 0.25, 0.25 /)
                W = 1.;

             elseif ( quadorder1 == 2 ) then
                call init_mat(Q,4,3); call init_vec(W,4)
                Q(1,:) = (/ 0.58541020d0, 0.13819660d0, 0.13819660d0/)
                Q(2,:) = (/ 0.13819660d0, 0.58541020d0, 0.13819660d0/)
                Q(3,:) = (/ 0.13819660d0, 0.13819660d0, 0.58541020d0/)
                Q(4,:) = (/ 0.13819660d0, 0.13819660d0, 0.13819660d0/)
                W = (/1, 1, 1, 1/)/4.;

             elseif ( quadorder1 == 3 ) then
                call init_mat(Q,5,3); call init_vec(W,5)
                Q(1,:) = (/0.25, 0.25, 0.25/)
                Q(2,:) = (/1/2., 1/6., 1/6./)
                Q(3,:) = (/1/6., 1/2., 1/6./)
                Q(4,:) = (/1/6., 1/6., 1/2./)
                Q(5,:) = (/1/6., 1/6., 1/6./)
                W = (/-4/5., 9/20., 9/20., 9/20., 9/20./)

             end if

             W = W/6.

        else ! -- Triangles

            if ( quadorder > 7 ) then ! check for valid quadrature order
                print*, 'Quadrature order too high for triangular quadrature'
                quadorder1 = 1;
            end if

            if ( quadorder1 == 1 ) then  ! set quad points and quadweights
                call init_mat(Q,1,2); call init_vec(W,1)
                Q(1,:) = (/0.3333333333333d0, 0.3333333333333d0 /)
                W = 1;

            elseif ( quadorder1 == 2 ) then
                call init_mat(Q, 3, 2 ); call init_vec(W,3)

                Q(1,:) = (/ 0.1666666666667d0, 0.1666666666667d0 /)
                Q(2,:) = (/ 0.6666666666667d0, 0.1666666666667d0 /)
                Q(3,:) = (/ 0.1666666666667d0, 0.6666666666667d0 /)

                W(1) = 0.3333333333333d0
                W(2) = 0.3333333333333d0
                W(3) = 0.3333333333333d0

            elseif ( quadorder1 <= 5 ) then
                call init_mat(Q, 7, 2 ); call init_vec(W,7)

                Q(1,:) = (/ 0.1012865073235d0, 0.1012865073235d0 /)
                Q(2,:) = (/ 0.7974269853531d0, 0.1012865073235d0 /)
                Q(3,:) = (/ 0.1012865073235d0, 0.7974269853531d0 /)
                Q(4,:) = (/ 0.4701420641051d0, 0.0597158717898d0 /)
                Q(5,:) = (/ 0.4701420641051d0, 0.4701420641051d0 /)
                Q(6,:) = (/ 0.0597158717898d0, 0.4701420641051d0 /)
                Q(7,:) = (/ 0.3333333333333d0, 0.3333333333333d0 /)

                W(1) = 0.1259391805448d0
                W(2) = 0.1259391805448d0
                W(3) = 0.1259391805448d0
                W(4) = 0.1323941527885d0
                W(5) = 0.1323941527885d0
                W(6) = 0.1323941527885d0
                W(7) = 0.2250000000000d0

             else
                call init_mat(Q, 13, 2); call init_vec(W,13)

                Q(1 ,:) = (/ 0.0651301029022d0, 0.0651301029022d0 /)
                Q(2 ,:) = (/ 0.8697397941956d0, 0.0651301029022d0 /)
                Q(3 ,:) = (/ 0.0651301029022d0, 0.8697397941956d0 /)
                Q(4 ,:) = (/ 0.3128654960049d0, 0.0486903154253d0 /)
                Q(5 ,:) = (/ 0.6384441885698d0, 0.3128654960049d0 /)
                Q(6 ,:) = (/ 0.0486903154253d0, 0.6384441885698d0 /)
                Q(7 ,:) = (/ 0.6384441885698d0, 0.0486903154253d0 /)
                Q(8 ,:) = (/ 0.3128654960049d0, 0.6384441885698d0 /)
                Q(9 ,:) = (/ 0.0486903154253d0, 0.3128654960049d0 /)
                Q(10,:) = (/ 0.2603459660790d0, 0.2603459660790d0 /)
                Q(11,:) = (/ 0.4793080678419d0, 0.2603459660790d0 /)
                Q(12,:) = (/ 0.2603459660790d0, 0.4793080678419d0 /)
                Q(13,:) = (/ 0.3333333333333d0, 0.3333333333333d0 /)

                W(1 ) = 0.0533472356088d0
                W(2 ) = 0.0533472356088d0
                W(3 ) = 0.0533472356088d0
                W(4 ) = 0.0771137608903d0
                W(5 ) = 0.0771137608903d0
                W(6 ) = 0.0771137608903d0
                W(7 ) = 0.0771137608903d0
                W(8 ) = 0.0771137608903d0
                W(9 ) = 0.0771137608903d0
                W(10) = 0.1756152576332d0
                W(11) = 0.1756152576332d0
                W(12) = 0.1756152576332d0
                W(13) =-0.1495700444677d0

            end if

            W=W/2.  !  ATTENTION ATTENTION WHY DIVIDE TO 2????? => pour etre conforme lors de l'integration sur le volume ...

         end if

      ! end of TRIANGULAR initialization

      else if(qt == 'PENTAHEDRAL') then

         if ( sdim == 3 ) then ! PENTAHEDRAL ELEMENT
            call init_mat(Q, 6, 3 ); call init_vec(W,6)

            Q(1 ,:) = (/ 0.1666666666667d0, 0.1666666666667d0, -0.577350269189626d0 /)
            Q(2 ,:) = (/ 0.6666666666667d0, 0.1666666666667d0, -0.577350269189626d0 /)
            Q(3 ,:) = (/ 0.1666666666667d0, 0.6666666666667d0, -0.577350269189626d0 /)
            Q(4 ,:) = (/ 0.1666666666667d0, 0.1666666666667d0,  0.577350269189626d0 /)
            Q(5 ,:) = (/ 0.6666666666667d0, 0.1666666666667d0,  0.577350269189626d0 /)
            Q(6 ,:) = (/ 0.1666666666667d0, 0.6666666666667d0,  0.577350269189626d0 /)

            W(1 ) = 0.3333333333333d0
            W(2 ) = 0.3333333333333d0
            W(3 ) = 0.3333333333333d0
            W(4 ) = 0.3333333333333d0
            W(5 ) = 0.3333333333333d0
            W(6 ) = 0.3333333333333d0

            W=W/2.
        else
            stop 'FIDES_util_quad : Le MTP6 est uniquement 3D'
        end if

      end if

   end subroutine util_quad

!==============================================================================
!---------------------------------------------------------------------------!
! Bibliothèque des fonctions d'interpolation (lagrange) et de leur dérivée  !
!---------------------------------------------------------------------------!

   subroutine elem_interp (Nv, dNdxi, typel, coord, sdim)

! Returns the Lagrange interpolant basis and its gradients w.r.t the
! parent coordinate system.
!
!         [N(xi),dNdxi(xi)] = FIDES_elem_interp(type-order,coord,dim)
!
!   Type is the toplogical class of finite element. It is in the general
!   form 'topology-#of nodes', i.e. a three node triangle is T3, a four
!   node quadralateral is Q4, a 4 node tetrahedra is H4, a 27 node brick
!   is B27, etc.
!
!   Coord is the parent coordinates at which the basis and its
!   gradients are to be evaluated at.
!
!   Presently defined are L2, L3, T3, T4 (cubic bubble), T6, Q4, Q9,
!   H4, H10, B8 and B27.
!
!   If dim is set to 2 then the vector representation of the N
!   matrix is returned.
!
! written by Jack Chessa
!            j-chessa@northwestern.edu
! Department of Mechanical Engineering
! Northwestern University

   use initialisation, only : init_mat, init_vec

   implicit none

   real*8, dimension(:,:), allocatable, intent(inout) :: Nv
   real*8, dimension(:,:), allocatable, intent(inout) :: dNdxi
   character(len=*), intent(in) :: typel
   real*8, dimension(:), intent(in) :: coord
   integer, intent(in), optional :: sdim

   integer :: dimen, i
   real*8, dimension(:), allocatable :: N
   real*8, dimension(:,:), allocatable :: ID
   real*8 :: xi, eta, zeta, r, s, t
   real*8 :: L

   if(present(sdim)) then
      dimen = sdim
   else
      dimen = 1
   end if

   select case (typel)

    case ('MBL3')
        !%%%%%%%%%%%%%%%%%% L3 THREE NODE LINE ELEMENT %%%%%%%%%%%%%%%%%%%%%
        !
        !    1---------2----------3
        !
        if (size(coord) < 1) then
            stop 'Error two coordinates needed for the MBL3 element'
        else
            allocate(N(3)); allocate(dNdxi(1,3))
            xi=coord(1);
            N = (/ (1-xi)*xi/(-2.) , (1+xi)*xi/2. , 1-xi**2. /)
            dNdxi(1,:) = (/ xi-.5 , xi+.5 ,-2.*xi /)
        end if

    case ('BEA2')
        !%%%%%%%%%%%%%%%%%% L2 TWO NODE BEAM ELEMENT  %%%%%%%%%%%%%%%%%%%%%%
        !
        !    1---------2
        !
        if (size(coord) < 1) then
            stop 'Error two coordinates needed for the BEA2 element'
        else
            allocate(N(4)); allocate(dNdxi(1,4))
            xi=coord(1);
            L=1.d0;
            N = (/ 1./4.*(1-xi)**2.*(2.+xi) ,  1./8.*L*(1.-xi)**2.*(1.+xi) , &
                &  1./4.*(1+xi)**2.*(2.-xi) , -1./8.*L*(1.+xi)**2.*(1.-xi)  /)
            dNdxi(1,:) = (/ 6.*xi/L , 3.*xi-1 , -6.*xi/L , 3.*xi+1. /)
            dNdxi = dNdxi / L
        end if

    case ('BAR2','BEF2','BEF3')
        !%%%%%%%%%%%%%%%%%% L2 TWO NODE FRAME ELEMENT  %%%%%%%%%%%%%%%%%%%%%%
        !
        !    1---------2
        !
        if (size(coord) < 1) then
            stop 'Error two coordinates needed for the BEF2 element'
        else
            allocate(N(6)); allocate(dNdxi(1,6))
            xi=coord(1);
            L=1.d0;

            N=(/ (1.-xi)/2. ,1./4.*(1.-xi)**2.*(2.+xi), 1./8.*L*(1.-xi)**2.*(1.+xi),&
              &  (1.+xi)/2. ,1./4.*(1.+xi)**2.*(2.-xi),-1./8.*L*(1.+xi)**2.*(1.-xi) /)
            dNdxi(1,:) = (/ -L/2. , 6.*xi/L , 3.*xi-1. , L/2.d0 , -6.*xi/L , 3.*xi+1.  /)
            dNdxi = dNdxi / L
        end if

     case ('MBT3')
        ! %%%%%%%%%%%%%%%% T3 THREE NODE TRIANGULAR ELEMENT %%%%%%%%%%%%%%%%%%
        !
        !               3
        !             /  \
        !            /    \
        !           /      \
        !          /        \
        !         /          \
        !        /            \
        !       /              \
        !      /                \
        !     /                  \
        !    1--------------------2

            if (size(coord) < 2) then
                stop 'Error two coordinates needed for the T3 element'
            else
                allocate(N(3)); allocate(dNdxi(3,2))
                xi=coord(1); eta=coord(2);
                N= (/1-xi-eta, xi, eta/)
                dNdxi(1,:) = (/-1.d0,-1.d0/)
                dNdxi(2,:) = (/1.d0,0.d0/)
                dNdxi(3,:) = (/0.d0,1.d0/)
            end if

        case ('MBT3fs')
            if (size(coord) < 2) then
                print*, 'Error two coordinates needed for the T3fs element'
                stop
            else
                allocate(N(3)); allocate(dNdxi(3,2))
                xi=coord(1); eta=coord(2)
                N = (/1-xi-eta, xi, eta /)
                dNdxi(1,:) = (/-1.d0,-1.d0/)
                dNdxi(2,:) = (/1.d0,0.d0/)
                dNdxi(3,:) = (/0.d0,1.d0/)
            end if

          case ('MBT4')
        !%%%%%%%%%% T4 FOUR NODE TRIANGULAR CUBIC BUBBLE ELEMENT %%%%%%%%%%%%
        !%
        !%               3
        !%             /  \
        !%            /    \
        !%           /      \
        !%          /        \
        !%         /          \
        !%        /      4     \
        !%       /              \
        !%      /                \
        !%     /                  \
        !%    1--------------------2

            if (size(coord) < 2) then
                stop 'Error two coordinates needed for the T4 element'
            else
                xi=coord(1); eta=coord(2)
                allocate(N(4)); allocate(dNdxi(4,2))
                N=(/1.-xi-eta-3.*xi*eta, xi*(1.-3.*eta), eta*(1.-3.*xi),9.*xi*eta/)
                dNdxi(1,:) = (/-1.-3.*eta, -1.-3.*xi/)
                dNdxi(2,:) = (/1.-3.*eta, -3.*xi/)
                dNdxi(3,:) = (/-3.*eta, 1.-3.*xi/)
                dNdxi(4,:) = (/9.*eta, 9.*xi/)
            end if

          case ('MBT6')
        !%%%%%%%%%%%%%%%%%% T6 SIX NODE TRIANGULAR ELEMENT %%%%%%%%%%%%%%%%%%
        !%
        !%               3
        !%             /  \
        !%            /    \
        !%           /      \
        !%          /        \
        !%         6          5
        !%        /            \
        !%       /              \
        !%      /                \
        !%     /                  \
        !%    1---------4----------2

            if (size(coord) < 2) then
                stop 'Error two coordinates needed for the T6 element'
            else
                xi=coord(1); eta=coord(2)
                allocate(N(6)); allocate(dNdxi(6,2))
                N = (/-(1.-xi-eta)*(1.-2.*(1-xi-eta)), -xi*(1.-2.*xi),    &
                   &  -eta*(1.-2.*eta)               , 4.*xi*(1.-xi-eta), &
                   &   4.*xi*eta                     , 4.*eta*(1.-xi-eta) /)

                dNdxi(1,:) = (/ 1.-4.*(1.-xi-eta), 1.-4.*(1.-xi-eta)/)
                dNdxi(2,:) = (/-1.+4.*xi         , 0.d0             /)
                dNdxi(3,:) = (/ 0.d0             ,-1.+4.*eta        /)
                dNdxi(4,:) = (/ 4.*(1.-2.*xi-eta),-4.*xi            /)
                dNdxi(5,:) = (/ 4.*eta           , 4.*xi            /)
                dNdxi(6,:) = (/-4.*eta           , 4.*(1.-xi-2.*eta)/)
            end if

          case ('MBQ4')
        !%%%%%%%%%%%%%%% Q4 FOUR NODE QUADRILATERIAL ELEMENT %%%%%%%%%%%%%%%%
        !%
        !%    4--------------------3
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    1--------------------2

            if (size(coord) < 2) then
                stop 'Error two coordinates needed for the Q4 element'
            else
                xi=coord(1); eta=coord(2)
                allocate(N(4)); allocate(dNdxi(4,2))
                N =0.25*(/(1.-xi)*(1.-eta), (1.+xi)*(1.-eta), &
                        & (1.+xi)*(1.+eta),(1.-xi)*(1.+eta)/)

                dNdxi(1,:) = 0.25*(/-(1.-eta), -(1.-xi)/)
                dNdxi(2,:) = 0.25*(/1.-eta, -(1.+xi)/)
                dNdxi(3,:) = 0.25*(/1.+eta, 1.+xi/)
                dNdxi(4,:) = 0.25*(/-(1.+eta), 1.-xi/)
            end if

          case ('MBQ8')
        !%%%%%%%%%%%%%%% Q4 FOUR NODE QUADRILATERIAL ELEMENT %%%%%%%%%%%%%%%%
        !%
        !%    4---------7----------3
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    8                    6
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    1---------5----------2

            if (size(coord) < 2) then
                stop 'Error two coordinates needed for the Q8 element'
            else
                xi=coord(1); eta=coord(2)
                allocate(N(8)); allocate(dNdxi(8,2))
                N =0.25*(/(1.-xi)*(1.-eta)*(-1.-xi-eta), &
                        & (1.+xi)*(1.-eta)*(-1.+xi-eta), &
                        & (1.+xi)*(1.+eta)*(-1.+xi+eta), &
                        & (1.-xi)*(1.+eta)*(-1.-xi+eta), &
                        & 2.*(1.-xi**2)*(1.-eta), &
                        & 2.*(1.+xi)*(1.-eta**2), &
                        & 2.*(1.-xi**2)*(1.+eta), &
                        & 2.*(1.-xi)*(1.-eta**2) /)

                dNdxi(1,:) = 0.25*(/ (1.-eta)*(2.*xi+eta), (1.-xi)*(xi+2.*eta)/)
                dNdxi(2,:) = 0.25*(/ (1.-eta)*(2.*xi-eta),-(1.+xi)*(xi-2.*eta)/)
                dNdxi(3,:) = 0.25*(/ (1.+eta)*(2.*xi+eta), (1.+xi)*(xi+2.*eta)/)
                dNdxi(4,:) = 0.25*(/-(1.+eta)*(-2.*xi+eta),(1.-xi)*(-xi+2.*eta)/)
                dNdxi(5,:) = (/-xi*(1.-eta)   , -(1.-xi**2)/2. /)
                dNdxi(6,:) = (/ (1.-eta**2)/2., -eta*(1.+xi)   /)
                dNdxi(7,:) = (/-xi*(1.+eta)   ,  (1.-xi**2)/2. /)
                dNdxi(8,:) = (/-(1.-eta**2)/2., -eta*(1.-xi)   /)
            end if

          case ('EJQ4')

        !%%%%%%%%%%%%%%%%%%% Q4 ELEMENT DE CONTACT 2D %%%%%%%%%%%%%%%%%
        !%                                                            %
        !%       4 O---------------------O 3      /                   %
        !%         |                     |        | epaisseur = 0     %
        !%       1 O---------------------O 2      /                   %
        !%                                                            %
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                xi = coord(1);
                allocate(N(4)); allocate(dNdxi(4,2))
                N=0.5*(/(1.-xi), (1.+xi), (1.+xi), (1.-xi)/)
                dNdxi(1,:) = 0.5*(/(-1.d0),0.d0/)
                dNdxi(2,:) = 0.5*(/(1.d0),0.d0/)
                dNdxi(3,:) = 0.5*(/(1.d0),0.d0/)
                dNdxi(4,:) = 0.5*(/(-1.d0),0.d0/)

          case ('EJQ6')

        !%%%%%%%%%%%%%%%%%%% Q6 ELEMENT DE CONTACT 2D %%%%%%%%%%%%%%%%%
        !%                                                            %
        !%                    6                                       %
        !%       4 O----------O----------O 3      /                   %
        !%         |                     |        | epaisseur = 0     %
        !%       1 O----------O----------O 2      /                   %
        !%                    5                                       %
        !%                                                            %
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                xi = coord(1);
                allocate(N(6)); allocate(dNdxi(6,2))
                N=0.5*(/xi*(xi-1.), xi*(xi+1.), xi*(xi+1.), xi*(xi-1.), 2.*(1.-xi**2), 2.*(1.-xi**2)/)
                dNdxi(1,:) = 0.5*(/(2.*xi-1.),0.d0/)
                dNdxi(2,:) = 0.5*(/(2.*xi+1.),0.d0/)
                dNdxi(3,:) = 0.5*(/(2.*xi+1.),0.d0/)
                dNdxi(4,:) = 0.5*(/(2.*xi-1.),0.d0/)
                dNdxi(5,:) = 0.5*(/(-4.*xi),0.d0/)
                dNdxi(6,:) = 0.5*(/(-4.*xi),0.d0/)


          case ('EJT6')
        !%%%%%%%%%%%%%%%%%%% P6 SIX NODE PENTAEDRAL JOINT ELEMENT %%%%%%%%%%%%%%%%%%%
        !%
        !%          6
        !%         /|\
        !%        / |
        !%       /  |  \
        !%      3   |
        !%      |\  |    \
        !%      |   4
        !%      | \   \    \                % Element d'interface 3D
        !%      |           \               % Epaisseur nulle
        !%      |  \      \  \
        !%      1           \
        !%       \   \        5
        !%         \         /
        !%           \ \    /
        !%             \   /
        !%               2
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

             xi = coord(1)
             eta= coord(2)

             allocate(N(6)); allocate(dNdxi(6,2))

             N = (/ 1.d0-xi-eta, xi, eta, 1.d0-xi-eta, xi, eta/)

             dNdxi(1,:) = (/-1.d0  , -1.d0 /)
             dNdxi(2,:) = (/ 1.d0  ,  0.d0 /)
             dNdxi(3,:) = (/ 0.d0  ,  1.d0 /)
             dNdxi(4,:) = (/-1.d0  , -1.d0 /)
             dNdxi(5,:) = (/ 1.d0  ,  0.d0 /)
             dNdxi(6,:) = (/ 0.d0  ,  1.d0 /)

    case ('MTT4')
        !%%%%%%%%%%%%%%%% H4 FOUR NODE TETRAHEDRAL ELEMENT %%%%%%%%%%%%%%%%%%
        !%
        !%             4
        !%           / | \
        !%          /  |  \
        !%         /   |   \
        !%        /    |    \
        !%       /     |     \
        !%      1 -----|------3
        !%         -   2  -

            if (size(coord) < 3) then
                stop 'Error three coordinates needed for the H4 element'
            else
                xi=coord(1); eta=coord(2); zeta=coord(3)
                allocate(N(4)); allocate(dNdxi(4,3))
                N = (/1-xi-eta-zeta, xi, eta, zeta/)
                dNdxi(1,:) = (/-1.d0, -1.d0, -1.d0/)
                dNdxi(2,:) = (/1.d0 , 0.d0 ,  0.d0/)
                dNdxi(3,:) = (/0.d0 , 1.d0 ,  0.d0/)
                dNdxi(4,:) = (/0.d0 , 0.d0 ,  1.d0/)
            end if

    case ('MTP6')
        !%%%%%%%%%%%%%%%%%%% P6 SIX NODE PENTAEDRAL ELEMENT %%%%%%%%%%%%%%%%%%%
        !%
        !%                  6
        !%               /  |\
        !%            /     |
        !%         /        |  \
        !%      3           |
        !%      |\          |    \
        !%      |           4
        !%      |  \               \
        !%      |
        !%      |    \               \
        !%      1
        !%       \     \               5
        !%         \                /
        !%            \  \        /
        !%               \     /
        !%                  2

        if (size(coord) < 3) then
           stop 'Error three coordinates needed for the P6 element'
        else
            r=coord(1); s=coord(2); t=coord(3)
            allocate(N(6)); allocate(dNdxi(6, 3))

            N = (/r*(1.-t)/2., s*(1.-t)/2., (1.-r-s)*(1.-t)/2., &
                  r*(1.+t)/2., s*(1.+t)/2., (1.-r-s)*(1.+t)/2. /)

            dNdxi(1,:) = .5*(/ (1.-t),   0.d0 ,    -r    /)
            dNdxi(2,:) = .5*(/  0.d0 ,  (1.-t),    -s    /)
            dNdxi(3,:) = .5*(/-(1.-t), -(1.-t),-(1.-r-s) /)
            dNdxi(4,:) = .5*(/ (1.+t),   0.d0 ,     r    /)
            dNdxi(5,:) = .5*(/  0.d0 ,  (1.+t),     s    /)
            dNdxi(6,:) = .5*(/-(1.+t), -(1.+t), (1.-r-s) /)
        end if

     case default
          stop 'elem_interp : Element non encore implante'
   end select

   if  (dimen == 1) then
        call init_mat(Nv, size(N), 1)
        Nv(:,1) = N(:)
   else
        !------------ Matrice identite ---------
        call init_mat(ID,dimen,dimen)
        do i =1, dimen
            ID(i,i) = 1.
        end do

      call init_mat(Nv, size(N)*dimen, dimen)
      do i = 1, size(N)
        !Nv(i*dimen:(i+1)*dimen-1,:) = N(i)*ID ! A verifier
        Nv((i-1)*dimen+1:i*dimen,:) = N(i)*ID ! JLT : A verifier
      end do
      deallocate(ID)
   end if

   deallocate(N);

   end subroutine elem_interp

!----------------------------------------------------------------------------!
!    Calculer les fonctions d'extrapolation (vers les noeuds) de valeurs     !
!                         connues aux points de Gauss                        !
!----------------------------------------------------------------------------!
subroutine elem_extrap(N,typel,coord)

    use variables, only :dime

    implicit none

    real*8, dimension(:), allocatable, intent(out) :: N
    real*8, dimension(dime), intent(in) :: coord
    integer, intent(in):: typel
    real*8 :: r, s, t, xi, eta, r3 !zeta,

    select case (typel)

    case (1)
        !:%%%%%%%%%%%%%%% UN SEUL POINT %%%%%%%%%%%%%%%%
        !%
        !%               3
        !%             /  \
        !%            /    \
        !%           /      \
        !%          /        \
        !%         /          \
        !%        /            \
        !%       /      x       \
        !%      /                \
        !%     /                  \
        !%    1--------------------2
        !%

        if (size(coord) < 2) then
            stop 'Error extrapolation : two coordinates needed for the T3 element'
        else
            allocate(N(1))
            N = (/ 1.d0 /)
        end if

    case (3)
        !%%%%%%%%%%%%%%%%%% T6 SIX NODE TRIANGULAR ELEMENT %%%%%%%%%%%%%%%%%%
        !%
        !%               3
        !%             /  \
        !%            /    \
        !%           /      \
        !%          /        \
        !%         6          5
        !%        /            \
        !%       /              \
        !%      /                \
        !%     /                  \
        !%    1---------4----------2

            if (size(coord) < 2) then
                stop 'Error extrapolation : two coordinates needed for the T6 element'
            else
                xi=coord(1); eta=coord(2);
                xi=2.*(xi-1./6.); eta=2.*(eta-1./6.);
                allocate(N(3));
                N= (/1-xi-eta, xi, eta/)
            end if


    case (4)
        !%%%%%%%%%%%%%% QUATRE POINTS %%%%%%%%%%%%%%%
        !%
        !%    4--------------------3
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    1--------------------2
        !%

        if (size(coord) < 2) then
            stop 'Error extrapolation : two coordinates needed for the Q4 element'
        else
            allocate(N(4))
            xi=coord(1); eta=coord(2); r3=sqrt(3.d0);
            xi=xi*r3; eta=eta*r3;
            N = 0.25*(/(1-xi)*(1-eta),(1+xi)*(1-eta),(1+xi)*(1+eta),(1-xi)*(1+eta)/)
        end if


    case (9)
        !%%%%%%%%%%%%%% NEUFS POINTS %%%%%%%%%%%%%%%
        !%
        !%    4---------7----------3
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    8         9          6
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    |                    |
        !%    1---------5----------2
        !%

        if (size(coord) < 2) then
            stop 'Error two coordinates needed for the Q4 element'
        else
            allocate(N(9))
            xi=coord(1); eta=coord(2); r3=sqrt(5.d0/3.d0);
            xi=xi*r3; eta=eta*r3;
            N =0.25*(/(1.-xi)*(1.-eta)*(xi*eta), &
                    & -1.*(1.+xi)*(1.-eta)*(xi*eta), &
                    & (1.+xi)*(1.+eta)*(xi*eta), &
                    & -1.*(1.-xi)*(1.+eta)*(xi*eta), &
                    & -2.*(1.-xi**2)*(1.-eta)*eta, &
                    & 2.*(1.+xi)*(1.-eta**2)*xi, &
                    & 2.*(1.-xi**2)*(1.+eta)*eta, &
                    & -2.*(1.-xi)*(1.-eta**2)*xi, &
                    & 4.* (1-xi**2)*(1-eta**2) /)
        end if

     case (6)
       ! %%%%%%%%%%%%%%%%%%% P6 SIX NODE PENTAEDRAL ELEMENT %%%%%%%%%%%%%%%%%%%
       !%
       !%                  6
       !%               /  |\
       !%            /     |
       !%         /        |  \
       !%      3           |
       !%      |\          |    \
       !%      |           4
       !%      |  \     /         \
       !%      |     /
       !%      |  / \               \
       !%      1
       !%       \     \               5
       !%         \                /
       !%            \  \        /
       !%               \     /
       !%                  2
       !%

       if (size(coord) < 3) then
            stop 'Error extrapolation : three coordinates needed for the P6 element'
       else
          allocate(N(6))

          r=coord(1); s=coord(2); t=coord(3);
          r=(r-1./6.)*2.; s=(s-1./6.)*2.; t=t*sqrt(3.d0);

          N = (/ r*(1.-t)/2., s*(1.-t)/2., (1.-r-s)*(1.-t)/2. , &
               & r*(1.+t)/2., s*(1.+t)/2., (1.-r-s)*(1.+t)/2. /)

       end if

    case default
        stop 'Extrapolation : Element not yet supported'
    end select

end subroutine elem_extrap

!================================================================================
!-------------------------------------------------------------------------------!
!                Calcul des matrices des fonctions d'interpolation              !
!                  des matrices des derivees des fonctions                      !
!                         d'interpolation et du jacobien                        !
!  Entrees :                                                                    !
!  - pt : point d'integration                                                   !
!  - e : numero de l'element                                                    !
!                                                                               !
!  Sorties :                                                                    !
!  - N : fonctions d'interpolation                                              !
!  - B : matrices des derivees des fonctions d'interpolation                    !
!  - detj : jacobien                                                            !
!-------------------------------------------------------------------------------!
   subroutine elem_B(N, B, detj, pt, e)

        use math
        use variables, only : dime, infele, vcor, kconec, ktypel, nomtype
        use initialisation, only : init_mat, init_vec

        implicit none

        real*8, dimension(:,:), allocatable, intent(inout) :: N
        real*8, dimension(:,:), allocatable, intent(inout) :: B
        real*8, intent(out) :: detj
        real*8, dimension(:), intent(in) :: pt
        integer, intent(in) :: e

        integer :: noel, ndln
        character(len=5) :: typel
        real*8, dimension(:,:), allocatable :: dNdxi
        real*8, dimension(dime,infele(ktypel(e))%nnel) :: vcorn

        typel = nomtype(ktypel(e))

        noel = infele(ktypel(e))%nnel
        ndln = infele(ktypel(e))%ndln

        vcorn = vcor(:,kconec(e,1:noel))

        !----- Matrice des fonctions d'interpolation -----
        call elem_interp(N, dNdxi, typel, pt)

      !----- Aiguillage vers les routines de calcul -------

        select case (typel(1:2))

         case('MB')
                call elem_B_MB(B, detj, typel, noel, ndln, vcorn, dNdxi)
         case('MT')
                call elem_B_MT(B, detj, typel, noel, ndln, vcorn, dNdxi)
         case('EJ')
                call elem_B_EJ(N, B, detj, typel, noel, ndln, vcorn, dNdxi)
         case('BE')
                call elem_B_BE(N, B, detj, typel, noel, ndln, vcorn, dNdxi)
         case('BA')
                call elem_B_BA(N, B, detj, typel, noel, ndln, vcorn, dNdxi)
         case default
                stop "elem_B : element non encore implante"
         end select

         deallocate(dNdxi)

   contains

      !-------------------------------------------------------------------------!
      !                  ELEMENTS MASSIFS BIDIMENSIONNELS                       !
      !                                                                         !
      !         Calcul des matrices des fonctions d'interpolation               !
      !             des matrices des derivees des fonctions                     !
      !                 d'interpolation et du jacobien                          !
      !  Entrees :                                                              !
      !  - typel : type de l'element                                            !
      !                                                                         !
      !  Sorties :                                                              !
      !  - N : fonctions d'interpolation                                        !
      !  - B : matrices des derivees des fonctions d'interpolation              !
      !  - detj : jacobien                                                      !
      !-------------------------------------------------------------------------!

           subroutine elem_B_MB(B, detj, typel, noel, ndln, vcorn, dNdxi)

                implicit none

                !real*8, dimension(:,:), allocatable, intent(inout) :: N
                real*8, dimension(:,:), allocatable, intent(inout) :: B
                real*8, dimension(:,:), intent(in) :: vcorn, dNdxi
                real*8, intent(out) :: detj
                integer, intent(in) :: noel, ndln
                character(len=5), intent(in) :: typel

                real*8, dimension(noel,dime) :: dNdx
                real*8, dimension(dime,dime) :: JO

                if (typel(1:2) /= 'MB') stop 'elem_B_MB : Le type d''element n''est pas correct !'

                !----- Determinant de la matrice jacobienne ------
                JO = matmul(vcorn ,dNdxi)
                detj = det(JO)

                !----- Matrice des derivees des fonctions d'interpolation
                dNdx  = matmul(dNdxi,INV(JO))    ! derivatives of N w.r.t XY

                !---------------------- Cas general ---------------
                if (dime == 2) then
                   call init_mat(B,3,ndln*noel)
                   B(1, 1:ndln*noel:ndln) = dNdx(:,1)
                   B(2, 2:ndln*noel:ndln) = dNdx(:,2)
                   B(3, 1:ndln*noel:ndln) = dNdx(:,2)
                   B(3, 2:ndln*noel:ndln) = dNdx(:,1)
                else
                   stop 'Calcul de B impossible : cas non prevu'
                end if

    end subroutine elem_B_MB

      !-------------------------------------------------------------------------!
      !                  ELEMENTS MASSIFS TRIDIMENSIONNELS                      !
      !                                                                         !
      !         Calcul des matrices des fonctions d'interpolation               !
      !             des matrices des derivees des fonctions                     !
      !                 d'interpolation et du jacobien                          !
      !  Entrees :                                                              !
      !  - pt : point d'integration                                             !
      !  - e : numero de l'element                                              !
      !  - typel : type de l'element                                            !
      !                                                                         !
      !  Sorties :                                                              !
      !  - N : fonctions d'interpolation                                        !
      !  - B : matrices des derivees des fonctions d'interpolation              !
      !  - detj : jacobien                                                      !
      !-------------------------------------------------------------------------!

           subroutine elem_B_MT(B, detj, typel, noel, ndln, vcorn, dNdxi)

                implicit none

                !real*8, dimension(:,:), allocatable, intent(inout) :: N
                real*8, dimension(:,:), allocatable, intent(inout) :: B
                real*8, dimension(:,:), intent(in) :: vcorn, dNdxi
                real*8, intent(out) :: detj
                integer, intent(in) :: noel, ndln
                character(len=5), intent(in) :: typel

                real*8, dimension(noel,dime) :: dNdx
                real*8, dimension(dime,dime) :: JO

                if (typel(1:2) /= 'MT') stop 'elem_B_MT : Le type d''element n''est pas correct !'

                !----- Determinant de la matrice jacobienne -------
                JO = matmul(vcorn ,dNdxi)
                detj = det(JO)

                !----- Matrice des derivees des fonctions d'interpolation
                dNdx  = matmul(dNdxi, INV(JO))    ! derivatives of N w.r.t XY

                !---------------------- Cas general ---------------
                if (dime == 3) then
                   call init_mat(B,6,ndln*noel)
                   B(1, 1:ndln*noel:ndln) = dNdx(:,1)
                   B(2, 2:ndln*noel:ndln) = dNdx(:,2)
                   B(3, 3:ndln*noel:ndln) = dNdx(:,3)
                   B(4, 1:ndln*noel:ndln) = dNdx(:,2)
                   B(4, 2:ndln*noel:ndln) = dNdx(:,1)
                   B(5, 3:ndln*noel:ndln) = dNdx(:,1)
                   B(5, 1:ndln*noel:ndln) = dNdx(:,3)
                   B(6, 2:ndln*noel:ndln) = dNdx(:,3)
                   B(6, 3:ndln*noel:ndln) = dNdx(:,2)
                else
                   stop 'Calcul de B impossible : cas non prevu'
                end if

           end subroutine elem_B_MT

      !-------------------------------------------------------------------------!
      !                                                                         !
      !         Calcul des matrices des fonctions d'interpolation               !
      !             des matrices des derivees des fonctions                     !
      !                 d'interpolation et du jacobien                          !
      !                 pour les elements EJQ4 et EJQ6                          !
      !  Entrees :                                                              !
      !  - pt : point d'integration                                             !
      !  - e : numero de l'element                                              !
      !  - typel : type de l'element                                            !
      !                                                                         !
      !  Sorties :                                                              !
      !  - N : fonctions d'interpolation                                        !
      !  - B : matrices des derivees des fonctions d'interpolation              !
      !  - detj : jacobien                                                      !
      !-------------------------------------------------------------------------!

        subroutine elem_B_EJ(N, B, detj, typel, noel, ndln, vcorn, dNdxi)

               implicit none

               real*8, dimension(:,:), allocatable, intent(inout) :: N
               real*8, dimension(:,:), allocatable, intent(inout) :: B
               real*8, dimension(:,:), intent(in) :: vcorn, dNdxi
               real*8, intent(out) :: detj
               integer, intent(in) :: noel, ndln
               character(len=5), intent(in) :: typel

               real*8, dimension(ndln,ndln*noel) :: Bfem
               real*8, dimension(ndln*noel,ndln*noel) :: A

               integer :: i
               real*8, dimension(dime) :: vt, vn, vecn, vect, vecp, a1, a2
               real*8, dimension(dime,dime) :: TP, v
               real*8 :: L, dxydxieta, dxzdxieta, dyzdxieta

               if (typel(1:2) /= 'EJ') stop 'elem_B_EJ : Le type d''element n''est pas correct !'

               A = 0.d0 ; Bfem = 0.d0 ; TP = 0.d0

               select case (dime)
                case (2)

                !----- Matrice de passage : transforme les deplacements (u,v) dans
                ! le repere global d'un noeud en deplacements (un,ut), normaux et
                ! tangents dans le repere local.
                v = matmul(vcorn,dNdxi)
                vt = v(:,1)
                L  = norme(vt)
                vt = vt/L
                vn = (/-vt(2),vt(1)/)

                do i = 1, dime
                  TP(i,:) = (/vn(i),vt(i)/)
                end do

                do i = 1,(ndln*noel-1),ndln
                    A(i:i+1,i:i+1) = TP
                end do

                ! Calcul de la matrice B
                if (typel == 'EJQ4') then
                    Bfem(1,1:ndln*noel:ndln) = (/-N(1,1), -N(2,1), N(3,1), N(4,1)/);
                    Bfem(2,2:ndln*noel:ndln) = (/-N(1,1), -N(2,1), N(3,1), N(4,1)/);
                elseif (typel=='EJQ6') then
                    Bfem(1,1:ndln*noel:ndln) = (/-N(1,1), -N(2,1), N(3,1), N(4,1), -N(5,1), N(6,1)/);
                    Bfem(2,2:ndln*noel:ndln) = (/-N(1,1), -N(2,1), N(3,1), N(4,1), -N(5,1), N(6,1)/);
                else
                    stop 'FIDES_elem_B_EJ : Element non-implante'
                end if

                call init_mat(B,size(Bfem,1),size(A,2))
                B = matmul(Bfem,A)

                ! Calcul de detj
                detj = L/2.0

             case (3)

                !----- Matrice de passage : transforme les deplacements (u,v,w) dans le
                ! repere global d'un noeud en deplacements (un,ut1,ut2), normaux et
                ! tangents dans le repere local.

                a1 = matmul(vcorn,dNdxi(:,1))
                a2 = matmul(vcorn,dNdxi(:,2))

                vect = a1/norme(a1)
                vecp = a2/norme(a2)
                vecn = cross(vect,vecp)

                do i = 1, dime
                   TP(i,:) = (/vecn(i),vect(i),vecp(i)/)
                end do

                do i = 1,(ndln*noel)-1, ndln
                   A(i:i+2, i:i+2) = TP
                end do

                ! Calcul de la matrice B
                if (typel=='EJT6') then
                    Bfem(1,1:ndln*noel:ndln) = (/-N(1,1), -N(2,1), -N(3,1), N(4,1), N(5,1), N(6,1)/)
                    Bfem(2,2:ndln*noel:ndln) = (/-N(1,1), -N(2,1), -N(3,1), N(4,1), N(5,1), N(6,1)/)
                    Bfem(3,3:ndln*noel:ndln) = (/-N(1,1), -N(2,1), -N(3,1), N(4,1), N(5,1), N(6,1)/)

                    dxydxieta = a1(1)*a2(2) - a1(2)*a2(1)
                    dxzdxieta = a1(1)*a2(3) - a1(3)*a2(1)
                    dyzdxieta = a1(2)*a2(3) - a1(3)*a2(2)

                    !Jacobien
                    detj = sqrt(dxydxieta**2 + dxzdxieta**2 + dyzdxieta**2)/4.

                elseif (typel=='EJT8') then
                    Bfem(1,1:ndln*noel:ndln) = (/-N(1,1), -N(2,1), -N(3,1), -N(4,1), N(5,1), N(6,1), N(7,1), N(8,1)/)
                    Bfem(2,2:ndln*noel:ndln) = (/-N(1,1), -N(2,1), -N(3,1), -N(4,1), N(5,1), N(6,1), N(7,1), N(8,1)/)
                    Bfem(3,3:ndln*noel:ndln) = (/-N(1,1), -N(2,1), -N(3,1), -N(4,1), N(5,1), N(6,1), N(7,1), N(8,1)/)

                    dxydxieta = a1(1)*a2(2) - a1(2)*a2(1)
                    dxzdxieta = a1(1)*a2(3) - a1(3)*a2(1)
                    dyzdxieta = a1(2)*a2(3) - a1(3)*a2(2)

                    !Jacobien
                    detj = sqrt(dxydxieta**2 + dxzdxieta**2 + dyzdxieta**2)/4.

                else
                   stop 'elem_B_EJ : element non encore implante'
                endif

                call init_mat(B,size(Bfem,1),size(A,2))
                B = matmul(Bfem,A)

          end select

      end subroutine elem_B_EJ

      !-------------------------------------------------------------------------!
      !                                                                         !
      !         Calcul des matrices des fonctions d'interpolation               !
      !             des matrices des derivees des fonctions                     !
      !                 d'interpolation et du jacobien                          !
      !                 pour les elements BEA2 et BEF2                          !
      !  Entrees :                                                              !
      !  - pt : point d'integration                                             !
      !  - e : numero de l'element                                              !
      !  - typel : type de l'element                                            !
      !                                                                         !
      !  Sorties :                                                              !
      !  - N : fonctions d'interpolation                                        !
      !  - B : matrices des derivees des fonctions d'interpolation              !
      !  - detj : jacobien                                                      !
      !-------------------------------------------------------------------------!

     subroutine elem_B_BE(N, B, detj, typel, noel, ndln, vcorn, dNdxi)

            use math, only : norme

            implicit none

            real*8, dimension(:,:), allocatable, intent(inout) :: N
            real*8, dimension(:,:), allocatable, intent(inout) :: B
            real*8, dimension(:,:), intent(in) :: vcorn, dNdxi
            real*8, intent(out) :: detj
            integer, intent(in) :: noel, ndln
            character(len=5), intent(in) :: typel

            real*8, dimension(:,:), allocatable :: NN, Nfem, R, Re, Bfem
            real*8, dimension(dime) :: e1, e2, e3
            real*8  :: LL, s, c

            if (typel(1:2) /= 'BE') stop 'elem_B_BE : Le type d''element n''est pas correct !'

            call init_mat(NN,size(N,1),size(N,2))
            NN = N
            deallocate(N)

            select case (dime)
              case (2)

                ! Calcul de la longueur de l'element poutre
                LL = norme(vcorn(:,2)-vcorn(:,1));

                ! Sinus et cosinus directeurs du repere local
                c = (vcorn(1,2)-vcorn(1,1))/LL
                s = (vcorn(2,2)-vcorn(2,1))/LL

                ! ELement BEA2
                if (typel == 'BEA2') then
                    call init_mat(Re,2,3)
                    Re(1,:) = (/  -s  ,  c   , 0.d0  /) ! point a revoir !!!!
                    Re(2,:) = (/ 0.d0 , 0.d0 , 1.d0  /) ! point a revoir !!!!

                    ! Calcul de R
                    call init_mat(R,2*noel,3*noel)
                    R(1:2,1:3)=Re;
                    R(3:4,4:6)=Re;

                    ! Correction de N
                    call init_mat(Nfem,1,4)
                    Nfem(1,:) = (/ NN(1,1), LL*NN(2,1), NN(3,1), LL*NN(4,1) /)

                    ! Calcul de la matrice B
                    call init_mat(Bfem,1,4)
                    Bfem(1,1:4) = (/dNdxi(1,1)/LL, dNdxi(1,2), dNdxi(1,3)/LL, dNdxi(1,4)/)
                    Bfem = Bfem / LL

                elseif (typel=='BEF2') then
                    call init_mat(Re,3,3)
                    Re(1,:) = (/   c   ,  s   , 0.d0 /)
                    Re(2,:) = (/  -s   ,  c   , 0.d0 /)
                    Re(3,:) = (/  0.d0 , 0.d0 , 1.d0 /)

                    ! Calcul de R
                    call init_mat(R,3*noel,3*noel)
                    R(1:3,1:3) = Re
                    R(4:6,4:6) = Re

                    ! correction de N
                    call init_mat(Nfem,2,6)
                    Nfem(1,:) = (/ NN(1,1) , 0.d0 , 0.d0    , NN(4,1) , 0.d0 , 0.d0    /)
                    Nfem(2,:) = (/ 0.d0 , NN(2,1) , LL*NN(3,1) , 0.d0 , NN(5,1) , LL*NN(6,1) /)

                    ! Calcul de la matrice B
                    call init_mat(Bfem,2,6)
                    Bfem(1,1:6) = (/ 2.*dNdxi(1,1) ,     0.d0      ,    0.d0    , &
                                  &  2.*dNdxi(1,4) ,     0.d0      ,    0.d0    /)
                    Bfem(2,1:6) = (/    0.d0    , dNdxi(1,2)/LL , dNdxi(1,3) , &
                                  &     0.d0    , dNdxi(1,5)/LL , dNdxi(1,6) /)
                    Bfem = Bfem / LL

                else
                    stop 'FIDES_elem_B_BE : Element non-implante'
                end if

                call init_mat(B,size(Bfem,1),size(R,2))
                call init_mat(N,size(Nfem,1),size(R,2))

                B = matmul(Bfem,R)
                N = matmul(Nfem,R)

                ! Calcul de detj
                detj = LL/2.d0;

            case (3)

                ! Calcul de la longueur de l'element  poutre
                LL = norme(vcorn(:,2)-vcorn(:,1))

                ! Vecteur unitaire
                e1 = (vcorn(:,2)-vcorn(:,1))/LL

                e2 = (/ e1(1)*e1(3) , e1(2)*e1(3) , -(e1(1)**2+e1(2)**2) /)
                if (norme(e2)==0.d0) then
                   e2 = (/ e1(1)*e1(2) , -(e1(1)**2+e1(3)**2) , e1(2)*e1(3) /)
                end if
                e2 = e2 / norme(e2)
                e3 = cross(e1,e2)

                ! Calcul de R
                call init_mat(Re,3,3)
                Re(1,:) = e1
                Re(2,:) = e2
                Re(3,:) = e3

                if (typel == 'BEF3') then

                    call init_mat(R,ndln*noel,ndln*noel)
                    R(1:3,1:3)     = Re
                    R(4:6,4:6)     = Re
                    R(7:9,7:9)     = Re
                    R(10:12,10:12) = Re

                    ! correction de N
                    call init_mat(Nfem,3,ndln*noel)
                    Nfem(1,:)=(/ NN(1,1), 0.d0, 0.d0 , 0.d0, 0.d0, NN(4,1), 0.d0, 0.d0, 0.d0 , 0.d0 /)
                    Nfem(2,:)=(/ 0.d0, NN(2,1), 0.d0 , 0.d0, LL*NN(3,1), 0.d0, NN(5,1), 0.d0, 0.d0, LL*NN(6,1)/)
                    Nfem(3,:)=(/ 0.d0, 0.d0 , NN(2,1), -LL*NN(3,1), 0.d0, 0.d0, 0.d0, NN(5,1), -LL*NN(6,1), 0.d0/)

                    ! Calcul de la matrice B
                    call init_mat(Bfem,4,ndln*noel)
                    Bfem(1,1:ndln*noel) = (/ 2.*dNdxi(1,1), 0.d0, 0.d0, 0.d0, 0.d0, 0.d0, &
                                           & 2.*dNdxi(1,4), 0.d0, 0.d0, 0.d0, 0.d0, 0.d0 /)
                    Bfem(2,1:ndln*noel) = (/ 0.d0, 0.d0, -dNdxi(1,2)/LL, 0.d0, dNdxi(1,3), 0.d0, &
                                           & 0.d0, 0.d0, -dNdxi(1,5)/LL, 0.d0, dNdxi(1,6), 0.d0 /)
                    Bfem(3,1:ndln*noel) = (/ 0.d0, dNdxi(1,2)/LL, 0.d0, 0.d0, 0.d0, dNdxi(1,3), &
                                           & 0.d0, dNdxi(1,5)/LL, 0.d0, 0.d0, 0.d0, dNdxi(1,6) /)
                    Bfem(4,1:ndln*noel) = (/ 0.d0, 0.d0, 0.d0, 2.*dNdxi(1,1), 0.d0, 0.d0, &
                                           & 0.d0, 0.d0, 0.d0, 2.*dNdxi(1,4), 0.d0, 0.d0 /)
                    Bfem = Bfem / LL

                end if

                call init_mat(B,size(Bfem,1),size(R,2))
                call init_mat(N,size(Nfem,1),size(R,2))

                B = matmul(Bfem,R)
                N = matmul(Nfem,R)

                ! Calcul de detj
                detj = LL/2.d0

            end select

            deallocate(R,Re,Bfem,Nfem)

        end subroutine elem_B_BE

      !-------------------------------------------------------------------------!
      !                                                                         !
      !         Calcul des matrices des fonctions d'interpolation               !
      !             des matrices des derivees des fonctions                     !
      !                 d'interpolation et du jacobien                          !
      !                 pour les elements BAR2                                  !
      !  Entrees :                                                              !
      !  - pt : point d'integration                                             !
      !  - e : numero de l'element                                              !
      !  - typel : type de l'element                                            !
      !                                                                         !
      !  Sorties :                                                              !
      !  - N : fonctions d'interpolation                                        !
      !  - B : matrices des derivees des fonctions d'interpolation              !
      !  - detj : jacobien                                                      !
      !-------------------------------------------------------------------------!

      subroutine elem_B_BA(N, B, detj, typel, noel, ndln, vcorn, dNdxi)
                use math, only : norme

                implicit none

                real*8, dimension(:,:), allocatable, intent(inout) :: N
                real*8, dimension(:,:), allocatable, intent(inout) :: B
                real*8, dimension(:,:), intent(in) :: vcorn, dNdxi
                real*8, intent(out) :: detj
                integer, intent(in) :: noel, ndln
                character(len=5), intent(in) :: typel

                real*8, dimension(:,:), allocatable :: NN
                real*8, dimension(1,noel*ndln) :: Nfem, Bfem
                real*8 :: LL

                if (typel(1:2) /= 'BA') stop 'elem_B_BA : Le type d''element n''est pas correct !'

                call init_mat(NN,size(N,1),size(N,2))
                NN = N
                deallocate(N)

                ! Calcul de la longueur de l'element barre
                LL = norme(vcorn(:,2)-vcorn(:,1))

                ! correction de N
                Nfem(1,:) = (/ NN(1,1) , NN(4,1) /)

                ! Calcul de la matrice B
                Bfem(1,:) = (/ 2.*dNdxi(1,1) , 2.*dNdxi(1,4) /)
                Bfem = Bfem / LL

                call init_mat(B,size(Bfem,1),size(Bfem,2))
                call init_mat(N,size(Nfem,1),size(Nfem,2))

                B = Bfem
                N = Nfem

                ! Calcul de detj
                detj = LL/2.d0;

                deallocate(NN)

      end subroutine elem_B_BA

   end subroutine elem_B

end module lib_elem
