
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include "helper_cuda.h"
#include "helper_functions.h"

#include <stdio.h>

#include "kernel.cuh"

__global__ void RGradient_kernel(const double *d_InputIMGR, const double *d_InputIMGT,const double* __restrict__ d_InputBiubicMatrix,
								 double *d_OutputIMGR, double *d_OutputIMGT, 
								 double *d_OutputIMGRx, double *d_OutputIMGRy,
								 double *d_OutputIMGTx, double *d_OutputIMGTy, double *d_OutputIMGTxy, double *d_OutputdtBicubic,
								 int width, int height)
{
	//Share memory for Bicubic computation
	__shared__ double d_TaoT[16];
	double d_AlphaT[16];

	//Map the threads to the pixel positions
	unsigned int row = blockIdx.y * blockDim.y + threadIdx.y;
	unsigned int col = blockIdx.x * blockDim.x + threadIdx.x;

	unsigned int i  = row * (width+2);		unsigned int j  = col;
	unsigned int i1 = (row+1) * (width+2);	unsigned int j1 = col +1;
	unsigned int i2 = (row+2) * (width+2);  unsigned int j2 = col +2;

	if(row < height && col < width){
		d_OutputIMGR[row*width+col]  = d_InputIMGR[i1+j1];
		d_OutputIMGRx[row*width+col] = 0.5 * (d_InputIMGR[i1+j2] - d_InputIMGR[i1+j]);
		d_OutputIMGRy[row*width+col] = 0.5 * (d_InputIMGR[i2+j1] - d_InputIMGR[i+j1]);

		d_OutputIMGT[row*width+col]  = d_InputIMGT[i1+j1];
		d_OutputIMGTx[row*width+col] = 0.5 * (d_InputIMGT[i1+j2] - d_InputIMGT[i1+j]);
		d_OutputIMGTy[row*width+col] = 0.5 * (d_InputIMGT[i2+j1] - d_InputIMGT[i+j1]);
		d_OutputIMGTxy[row*width+col]= 0.25 * (d_InputIMGT[i2+j2] - d_InputIMGT[i+j2] - d_InputIMGT[i2+j] + d_InputIMGT[i+j]);
	}
	__syncthreads();

	if(row < height-1 && col < width-1){
		d_TaoT[0] = d_OutputIMGT[row*(width-1)+col];
		d_TaoT[1] = d_OutputIMGT[row*(width-1)+col+1];
		d_TaoT[2] = d_OutputIMGT[(row+1)*(width-1)+col];
		d_TaoT[3] = d_OutputIMGT[(row+1)*(width-1)+col+1];
		d_TaoT[4] = d_OutputIMGTx[row*(width-1)+col];
		d_TaoT[5] = d_OutputIMGTx[row*(width-1)+col+1];
		d_TaoT[6] = d_OutputIMGTx[(row+1)*(width-1)+col];
		d_TaoT[7] = d_OutputIMGTx[(row+1)*(width-1)+col+1];
		d_TaoT[8] = d_OutputIMGTy[row*(width-1)+col];
		d_TaoT[9] = d_OutputIMGTy[row*(width-1)+col+1];
		d_TaoT[10] = d_OutputIMGTy[(row+1)*(width-1)+col];
		d_TaoT[11] = d_OutputIMGTy[(row+1)*(width-1)+col+1];
		d_TaoT[12] = d_OutputIMGTxy[row*(width-1)+col];
		d_TaoT[13] = d_OutputIMGTxy[row*(width-1)+col+1];
		d_TaoT[14] = d_OutputIMGTxy[(row+1)*(width-1)+col];
		d_TaoT[15] = d_OutputIMGTxy[(row+1)*(width-1)+col+1];
		for(int k=0; k<16; k++){
			d_AlphaT[k] = 0.0;
			for(int l=0; l<16; l++){
				d_AlphaT[k] += (d_InputBiubicMatrix[k*16+l] * d_TaoT[l]);
			}
		}
		d_OutputdtBicubic[((row*(width-1)+col)*4+0)*4+0] = d_AlphaT[0];
		d_OutputdtBicubic[((row*(width-1)+col)*4+0)*4+1] = d_AlphaT[1];
		d_OutputdtBicubic[((row*(width-1)+col)*4+0)*4+2] = d_AlphaT[2];
		d_OutputdtBicubic[((row*(width-1)+col)*4+0)*4+3] = d_AlphaT[3];
		d_OutputdtBicubic[((row*(width-1)+col)*4+1)*4+0] = d_AlphaT[4];
		d_OutputdtBicubic[((row*(width-1)+col)*4+1)*4+1] = d_AlphaT[5];
		d_OutputdtBicubic[((row*(width-1)+col)*4+1)*4+2] = d_AlphaT[6];
		d_OutputdtBicubic[((row*(width-1)+col)*4+1)*4+3] = d_AlphaT[7];
		d_OutputdtBicubic[((row*(width-1)+col)*4+2)*4+0] = d_AlphaT[8];
		d_OutputdtBicubic[((row*(width-1)+col)*4+2)*4+1] = d_AlphaT[9];
		d_OutputdtBicubic[((row*(width-1)+col)*4+2)*4+2] = d_AlphaT[10];
		d_OutputdtBicubic[((row*(width-1)+col)*4+2)*4+3] = d_AlphaT[11];
		d_OutputdtBicubic[((row*(width-1)+col)*4+3)*4+0] = d_AlphaT[12];
		d_OutputdtBicubic[((row*(width-1)+col)*4+3)*4+1] = d_AlphaT[13];
		d_OutputdtBicubic[((row*(width-1)+col)*4+3)*4+2] = d_AlphaT[14];
		d_OutputdtBicubic[((row*(width-1)+col)*4+3)*4+3] = d_AlphaT[15];
	}
	else{
		d_OutputdtBicubic[((row*(width-1)+col)*4+0)*4+0] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+0)*4+1] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+0)*4+2] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+0)*4+3] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+1)*4+0] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+1)*4+1] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+1)*4+2] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+1)*4+3] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+2)*4+0] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+2)*4+1] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+2)*4+2] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+2)*4+3] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+3)*4+0] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+3)*4+1] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+3)*4+2] = 0;
		d_OutputdtBicubic[((row*(width-1)+col)*4+3)*4+3] = 0;
	}
	

}

void launch_kernel(const double *h_InputIMGR, const double *h_InputIMGT,
								 double *h_OutputIMGR, double *h_OutputIMGT, 
								 double *h_OutputIMGRx, double *h_OutputIMGRy,
								 double *h_OutputIMGTx, double *h_OutputIMGTy, double *h_OutputIMGTxy, double *h_OutputdTBicubic,
								 int width, int height)
{
	double *d_InputIMGR, *d_InputIMGT, *d_InputBiubicMatrix;
	double *d_OutputIMGR, *d_OutputIMGT, *d_OutputIMGRx, *d_OutputIMGRy, *d_OutputIMGTx, *d_OutputIMGTy, *d_OutputIMGTxy;
	double *d_OutputdTBicubic;
	
	const static double h_InputBicubicMatrix[16*16] = {  1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
													0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ,
													-3, 3, 0, 0, -2, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
													2, -2, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
													0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 
													0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 ,
													0, 0, 0, 0, 0, 0, 0, 0, -3, 3, 0, 0, -2, -1, 0, 0,
													0, 0, 0, 0, 0, 0, 0, 0, 2, -2, 0, 0, 1, 1, 0, 0 , 
													-3, 0, 3, 0, 0, 0, 0, 0, -2, 0, -1, 0, 0, 0, 0, 0, 
													0, 0, 0, 0, -3, 0, 3, 0, 0, 0, 0, 0, -2, 0, -1, 0,  
													9, -9, -9, 9, 6, 3, -6, -3, 6, -6, 3, -3, 4, 2, 2, 1 , 
													-6, 6, 6, -6, -3, -3, 3, 3, -4, 4, -2, 2, -2, -2, -1, -1, 
													2, 0, -2, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0 , 
													0, 0, 0, 0, 2, 0, -2, 0, 0, 0, 0, 0, 1, 0, 1, 0 , 
													-6, 6, 6, -6, -4, -2, 4, 2, -3, 3, -3, 3, -2, -1, -2, -1,
													4, -4, -4, 4, 2, 2, -2, -2, 2, -2, 2, -2, 1, 1, 1, 1 
												   };

	checkCudaErrors(cudaMalloc((void**)&d_InputIMGR, (width+2)*(height+2)*sizeof(double)));
	checkCudaErrors(cudaMalloc((void**)&d_InputIMGT, (width+2)*(height+2)*sizeof(double)));
	checkCudaErrors(cudaMalloc((void**)&d_InputBiubicMatrix, 16*16*sizeof(double)));

	checkCudaErrors(cudaMemcpy(d_InputIMGR,h_InputIMGR,(width+2)*(height+2)*sizeof(double),cudaMemcpyHostToDevice));
	checkCudaErrors(cudaMemcpy(d_InputIMGT,h_InputIMGT,(width+2)*(height+2)*sizeof(double),cudaMemcpyHostToDevice));
	checkCudaErrors(cudaMemcpy(d_InputBiubicMatrix,h_InputBicubicMatrix,16*16*sizeof(double),cudaMemcpyHostToDevice));
	
	checkCudaErrors(cudaMalloc((void**)&d_OutputIMGR, width*height*sizeof(double)));
	checkCudaErrors(cudaMalloc((void**)&d_OutputIMGT, width*height*sizeof(double)));
	checkCudaErrors(cudaMalloc((void**)&d_OutputIMGRx, width*height*sizeof(double)));
	checkCudaErrors(cudaMalloc((void**)&d_OutputIMGRy, width*height*sizeof(double)));
	checkCudaErrors(cudaMalloc((void**)&d_OutputIMGTx, width*height*sizeof(double)));
	checkCudaErrors(cudaMalloc((void**)&d_OutputIMGTy, width*height*sizeof(double)));
	checkCudaErrors(cudaMalloc((void**)&d_OutputIMGTxy, width*height*sizeof(double)));
	checkCudaErrors(cudaMalloc((void**)&d_OutputdTBicubic, (width-1)*(height-1)*4*4*sizeof(double)));

	dim3 dimB(BLOCK_SIZE,BLOCK_SIZE,1);
	dim3 dimG((width-1)/BLOCK_SIZE+1,(height-1)/BLOCK_SIZE+1,1);

	RGradient_kernel<<<dimG, dimB>>>(d_InputIMGR,d_InputIMGT,d_InputBiubicMatrix,
								d_OutputIMGR, d_OutputIMGT, 
								 d_OutputIMGRx, d_OutputIMGRy,
								 d_OutputIMGTx, d_OutputIMGTy, d_OutputIMGTxy,d_OutputdTBicubic,
								 width, height);

	cudaDeviceSynchronize();

	checkCudaErrors(cudaMemcpy(h_OutputIMGR,d_OutputIMGR,width*height*sizeof(double),cudaMemcpyDeviceToHost));
	checkCudaErrors(cudaMemcpy(h_OutputIMGT,d_OutputIMGT,width*height*sizeof(double),cudaMemcpyDeviceToHost));
	checkCudaErrors(cudaMemcpy(h_OutputIMGRx,d_OutputIMGRx,width*height*sizeof(double),cudaMemcpyDeviceToHost));
	checkCudaErrors(cudaMemcpy(h_OutputIMGRy,d_OutputIMGRy,width*height*sizeof(double),cudaMemcpyDeviceToHost));
	checkCudaErrors(cudaMemcpy(h_OutputIMGTx,d_OutputIMGTx,width*height*sizeof(double),cudaMemcpyDeviceToHost));
	checkCudaErrors(cudaMemcpy(h_OutputIMGTy,d_OutputIMGTy,width*height*sizeof(double),cudaMemcpyDeviceToHost));
	checkCudaErrors(cudaMemcpy(h_OutputIMGTxy,d_OutputIMGTxy,width*height*sizeof(double),cudaMemcpyDeviceToHost));
	checkCudaErrors(cudaMemcpy(h_OutputdTBicubic,d_OutputdTBicubic,(width-1)*(height-1)*4*4*sizeof(double),cudaMemcpyDeviceToHost));

	checkCudaErrors(cudaFree(d_OutputIMGR));
	checkCudaErrors(cudaFree(d_OutputIMGT));
	checkCudaErrors(cudaFree(d_OutputIMGRx));
	checkCudaErrors(cudaFree(d_OutputIMGRy));
	checkCudaErrors(cudaFree(d_OutputIMGTx));
	checkCudaErrors(cudaFree(d_OutputIMGTy));
	checkCudaErrors(cudaFree(d_OutputIMGTxy));
	checkCudaErrors(cudaFree(d_OutputdTBicubic));
}
