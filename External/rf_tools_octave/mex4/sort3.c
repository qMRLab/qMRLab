void sort3(n,ra,rb,rc)
int n;
float ra[],rb[],rc[];
{
	int j,*iwksp,*ivector();
	float *wksp,*vector();
	void indexx(),free_vector(),free_ivector();

	iwksp=ivector(1,n);
	wksp=vector(1,n);
	indexx(n,ra,iwksp);
	for (j=1;j<=n;j++) wksp[j]=ra[j];
	for (j=1;j<=n;j++) ra[j]=wksp[iwksp[j]];
	for (j=1;j<=n;j++) wksp[j]=rb[j];
	for (j=1;j<=n;j++) rb[j]=wksp[iwksp[j]];
	for (j=1;j<=n;j++) wksp[j]=rc[j];
	for (j=1;j<=n;j++) rc[j]=wksp[iwksp[j]];
	free_vector(wksp,1,n);
	free_ivector(iwksp,1,n);
}
