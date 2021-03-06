%-------------------------------------------------------------------------%
%          MODELISATION PAR LA METHODE DES ELEMENTS FINIS                 %
%          DU COMPORTEMENT D'UNE BARRE SOUMISE A UNE TRACTION             %
%-------------------------------------------------------------------------%
clear all;
%
% Donn�es du probl�me :
% ---------------------
%
% D�finition de la g�om�trie du tirant
%  - Longueur du tirant   (m)                           <= Donn�e d'entr�e
L = 1.750;
%  - Densit� de fissures au m lineaire
den_fiss = 30/L;
%  - Section du tirant    (m x m)                       <= Donn�e d'entr�e
h = .072;
ep = .8;
A  = h*ep;
%-------------------------------------------------------------------------
%  - Section totale d'acier de diametre D (n_s aciers)  <= Donn�e d'entr�e
D_s = .012;
n_s = 5;
A_s = n_s*1/4*pi*D_s^2;
%-------------------------------------------------------------------------
% Chargement appliqu�
%  - D�placement impos� en x=L (m)                      <= Donn�e d'entr�e
Uimp = .00005;
UimpEvol = [0:.1:1,1:1:200]*Uimp;
%
% Discr�tisation de la g�om�trie :
% -------------------------------
%
% Nombre d'�l�ments sur la longueur                     <= Donn�e d'entr�e
nelt = 50;
nno = nelt+1;%           Nombre de noeuds du maillage
Le  = L/nelt;%              Longueur de l'�l�ment
xe  = (0:1:nelt)*Le;%       Coordonn�es des noeuds du maillage
%-------------------------------------------------------------------------
%  - R�sistance � la traction des �l�ments

dataExp1 = importdata('./n_fiss.txt');
iddata = find(dataExp1(:,2)<den_fiss*L);
Xf = dataExp1(iddata,1);
Yf = dataExp1(iddata,2);

v = random('Unif',0,1,nelt,1);
id = find(Yf~=0);

id1 = id(1);
id0 = id1-1;
id = [id0;id];

xp =Xf(id);
yp = Yf(id) / max(Yf(id));
for i=1:length(v)
    F(i,1) = interp1(yp,xp,v(i));
end

% m = .11;
% v = .001;
% mu = log((m^2)/sqrt(v+m^2));
% sigma = sqrt(log(v/(m^2)+1));
% for ie=1:nelt
%      F(ie,1)=0;
%      while (F(ie,1)<.1)
%          F(ie,1) = wblrnd(.15,2,1,1);
%      end
% end
RT = F/A;
RTmin = min(RT);
RTmax = max(RT);
alp = (RT-RTmin)/(RTmax-RTmin);

%-------------------------------------------------------------------------
%  - Probabilit� d'avoir un �l�ment qui fissure
p_fiss = den_fiss * Le;
rupt_el = binornd(1,p_fiss,nelt,1);
RT = (1-rupt_el)*1.e10 + rupt_el.*RT;
n_fiss = sum(rupt_el);
pn_fiss = n_fiss/nelt;
%-------------------------------------------------------------------------
% Propri�t�s "mat�riau"
%  - Module acier (MPa)                                 <= Donn�e d'entr�e
E_s = 200000;
%  - Module b�ton (MPa)                                 <= Donn�e d'entr�e
E_b = 35000;
%  - Module �quivalent b�ton arm� non fissur�
E_m  = (A_s*E_s+(A-A_s)*E_b)/A;
%  - Module �quivalent b�ton arm� fissur�
E_ms = (A_s*E_s)/A;
%E_mfmoy = n_fiss*E_m*E_ms/(nelt*E_m-(nelt-n_fiss)*E_ms);
E_mfmoy = pn_fiss*E_m*E_ms/(E_m-(1-pn_fiss)*E_ms);
pn_fissmin = n_fiss/nelt;
E_min = pn_fissmin*E_m*E_ms/(E_m-(1-pn_fissmin)*E_ms);
%
% lambd = 1/(E_mfmoy-E_min);
% v = random('Unif',0,1,nelt,1);

for i=1:length(v)
    E_mf(i,1) = 1/(1/E_min+alp(i)*(1/E_mfmoy-1/E_min));
%     E_mf(i,1) = 0 ;
%     while (E_mf(i,1)<E_min)
%         E_mf(i,1) = E_min-1/lambd*log(1-v(i));
%     end
end
E_mf = rupt_el.*E_mf;

%
% Initialisations pour algorithme non-lin�aire :
% ---------------------------------------------
ndlt = 1*nno;%           Nombre de degr�s de libert� total
U = zeros(ndlt,1);%      Vecteur global des d�placements nodaux
%
% Boucle sur le nombre de pas de calculs :
% ---------------------------------------
disp(' ');
npas = length(UimpEvol);
lam=ones(npas,1);
Dini(1:nelt) = 0.;
D(1:nelt) = 0.;

for ipas=1:npas
    %
    % Initialisation pour chaque pas
    % ------------------------------
    nconv = 'false';
    %lam(ipas) = ipas;%            Facteur multiplicateur de la charge
    dUt = zeros(ndlt,1);%         Incr�ment total de chargement
    disp(['Pas de calcul n�: ',num2str(ipas),'  Coefficient de charge ',num2str(lam(ipas))]);
    %
    % Boucle sur le nombre de pas de calculs :
    % ---------------------------------------
    for iter=1:5000
        %
        % Initialisation du syst�me matriciel :
        % -------------------------------------
        K = zeros(ndlt,ndlt);%     Matrice de rigidit�
        R = zeros(ndlt,1);%        Vecteur r�sidu
        Fint = zeros(ndlt,1);%     Vecteur d'efforts int�rieurs
        sig  = zeros(nelt,1);%     Vecteur contenant les contraintes sur les �l�ments
        %
        % Boucle sur le nombre d'�l�ments :
        % ---------------------------------
        for ie=1:nelt
            %
            % Calcul et int�gration des contraintes sur l'�l�ment
            % ---------------------------------------------------
            eps = (U(ie+1,1)-U(ie,1))/Le;%   D�formation sur l'�l�ment
            S = A;
            E = E_m;
            %
            D(ie) = Dini(ie);
            if (eps>RT(ie)/E_m)
                 D(ie) = 1 - RT(ie)/(E_m*eps);
                 if (eps>RT(ie)/E_mf(ie))
                    D(ie) = 1 - E_mf(ie)/E_m;
                 end
                D(ie) = max(Dini(ie),D(ie));
                D(ie) = min(1.d0,D(ie));
            end
            sig(ie) = (1-D(ie))*E * eps ;%      Contrainte finale dans l'�l�ment
%             sig(ie) = E*eps;%                  Pr�dicteur �lastique des contraintes
%             if sig(ie) > RT(ie)%               Calcul de la d�formation plastique
%                 E = E_mf(ie);
%                 sig(ie) = E*eps;%                  Pr�dicteur �lastique des contraintes
%             end
            Fint_e = sig(ie)*S*[-1;1];%             Vecteur �l�mentaire d'effort int�rieur
            Fint(ie:ie+1,1) = Fint(ie:ie+1,1) + Fint_e;%  Vecteur global d'effort int�rieur
            %
            % Calcul et assemblage du vecteur r�sidu
            % --------------------------------------
            R(ie:ie+1,1) = R(ie:ie+1,1) + (Fint_e );
            %
            % Calcul et assemblage de la matrice de rigidit�
            % ----------------------------------------------
            K(ie:ie+1,ie:ie+1) = K(ie:ie+1,ie:ie+1) + (1-D(ie))*E*S/Le*[1,-1;-1,1];
        end
        %
        % Prise en compte des conditions aux fronti�res en x=0 et x=L
        % -----------------------------------------------------------
        if iter == 1
            R = R - K(:,ndlt)*lam(ipas)*(-Uimp);
            R(ndlt,1) = -lam(ipas)*Uimp;
        else
            R(ndlt,1) = 0;
        end
        K(1,:) = zeros(1,ndlt);
        K(:,1) = zeros(ndlt,1);
        K(1,1) = 1;
        R(1,1) = 0;
        %
        K(ndlt,:) = zeros(1,ndlt);
        K(:,ndlt) = zeros(ndlt,1);
        K(ndlt,ndlt) = 1;
         
        %
        % R�solution du syst�me matriciel :
        % --------------------------------
        dU = -inv(K)*R;
        dUt = dUt + dU;
        U  = U + dU;
        %
        % Test de convergence :
        % ---------------------
        ndu= norm(dU)/(norm(dUt)+1.D-20);
        disp(['It�ration ',num2str(iter),'  -  Crit�re : ',num2str(ndu)]);
        if(ndu < 1.e-04),
            nconv = 'true';
            disp(' ');
            break;
        end
    end%----- Fin de boucle sur les it�rations internes
    if strcmp(nconv,'false'),break;end;
    %
    % Stockage des r�sultats � chaque pas de temps
    %---------------------------------------------
    resu(ipas).depl = U; %    d�placements : ux   (noeuds)
    resu(ipas).cont = sig;%   contraintes  : sxx  (pt de Gauss : centre �l�ment)
    resu(ipas).fiss = nnz(D);
    %
    % Stockage de la courbe globale
    %------------------------------
    FX(ipas) = U(ndlt,1);
    FY(ipas) = Fint(ndlt,1);
end%----- Fin de boucle sur le nombre de pas de calculs
%
% Post-traitement :
% ----------------
%
% Trac�s

break

figure(1);
plot([0,FX],[0,FY],'g-*');title('Courbe globale effort / d�placement');
hold on
plot([0,FX],[0,E_s*A_s/L*FX])

dataExp2 = importdata('./c_glob.txt');
Fexp_X=dataExp2(:,1);
Fexp_Y=dataExp2(:,2);
plot(Fexp_X,Fexp_Y,'r-');

legend('Solution �l�ments finis',4);
%
 for ipas=1:npas
     U = resu(ipas).depl;
     ouv(ipas) = mean(nonzeros(rupt_el.*(U(2:nelt+1,1)-U(1:nelt,1))));     
     n_fiss(ipas) = resu(ipas).fiss;
     eff_fiss(ipas) = FY(ipas);
 end

 % Nombre de fissures
figure(2)
plot(eff_fiss,n_fiss,'g-*')
hold on
plot(Xf,Yf,'r')

 % Ouvertures de fissures
figure(3)
plot(eff_fiss,ouv,'g-*')
hold on
dataExp3 = importdata('./ouv_fiss.txt');
ouv_X=dataExp3(:,1);
ouv_Y=dataExp3(:,2);
plot(ouv_X,ouv_Y,'r-');
hold on