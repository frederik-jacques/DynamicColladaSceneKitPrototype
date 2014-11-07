//
//  GameViewController.m
//  PrototypeSceneKit
//
//  Created by Frederik Jacques on 07/11/14.
//  Copyright (c) 2014 Frederik Jacques. All rights reserved.
//

#import "GameViewController.h"
#import "AFURLSessionManager.h"
#import "SSZipArchive.h"

@implementation GameViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    // Download zipfile
    [self downloadZip];
    
}

- (void)downloadZip {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:@"http://www.the-nerd.be/product-1-optimized.scnassets.zip"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
        
        // Unzip the archive
        NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *inputPath = [documentsDirectory stringByAppendingPathComponent:@"/product-1-optimized.scnassets.zip"];
        
        NSError *zipError = nil;
        
        [SSZipArchive unzipFileAtPath:inputPath toDestination:documentsDirectory overwrite:YES password:nil error:&zipError];
        
        if( zipError ){
            NSLog(@"[GameVC] Something went wrong while unzipping: %@", zipError.debugDescription);
        }else {
            NSLog(@"[GameVC] Archive unzipped successfully");
            [self startScene];
        }
        
    }];
    [downloadTask resume];
    
}


- (void)startScene {
    
    // Load the downloaded scene
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    documentsDirectoryURL = [documentsDirectoryURL URLByAppendingPathComponent:@"product-1-optimized.scnassets/cube.dae"];
    
    SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:documentsDirectoryURL options:nil];
    
    // Get reference to the cube node
    SCNNode *theCube = [sceneSource entryWithIdentifier:@"Cube" withClass:[SCNNode class]];
    
    // Create a new scene
    SCNScene *scene = [SCNScene scene];
    
    // create and add a camera to the scene
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:cameraNode];
    
    // place the camera
    cameraNode.position = SCNVector3Make(0, 0, 15);
    
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 10, 10);
    [scene.rootNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];
    
    // Add our cube to the scene
    [scene.rootNode addChildNode:theCube];
    
// retrieve the SCNView
SCNView *scnView = (SCNView *)self.view;

// set the scene to the view
scnView.scene = scene;

// allows the user to manipulate the camera
scnView.allowsCameraControl = YES;

// show statistics such as fps and timing information
scnView.showsStatistics = YES;

// configure the view
scnView.backgroundColor = [UIColor blackColor];
    
    // add a tap gesture recognizer
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObject:tapGesture];
    [gestureRecognizers addObjectsFromArray:scnView.gestureRecognizers];
    scnView.gestureRecognizers = gestureRecognizers;
    
}

- (void) handleTap:(UIGestureRecognizer*)gestureRecognize
{
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;
    
    // check what nodes are tapped
    CGPoint p = [gestureRecognize locationInView:scnView];
    NSArray *hitResults = [scnView hitTest:p options:nil];
    
    // check that we clicked on at least one object
    if([hitResults count] > 0){
        // retrieved the first clicked object
        SCNHitTestResult *result = [hitResults objectAtIndex:0];
        
        // get its material
        SCNMaterial *material = result.node.geometry.firstMaterial;
        
        // highlight it
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.5];
        
        // on completion - unhighlight
        [SCNTransaction setCompletionBlock:^{
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.5];
            
            material.emission.contents = [UIColor blackColor];
            
            [SCNTransaction commit];
        }];
        
        material.emission.contents = [UIColor redColor];
        
        [SCNTransaction commit];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
